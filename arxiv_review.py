#!/usr/bin/env python3
"""
ArXiv Weekly Paper Review — 顶会严苛审稿人版
每周抓取 arXiv 论文，AI 审稿人筛选，保存到本地报告。

关键设计：
1. 时间窗口过滤：只保留过去 7 天内更新的论文
2. 降低幻觉：prompt 中强调严格基于提供的摘要推理
3. 身份设定：顶会严苛审稿人
"""

import xml.etree.ElementTree as ET
import requests
import json
import os
import sys
import time
from datetime import datetime, timedelta

# 绕过代理
PROXIES = {"http": "http://127.0.0.1:7890", "https": "http://127.0.0.1:7890"}

def fetch_arxiv_papers(category='cs', max_results=50):
    """从 arXiv 获取最新论文，并过滤过去 7 天内更新的"""
    url = f'http://export.arxiv.org/api/query?search_query={category}&sortBy=submittedDate&sortOrder=descending&max_results={max_results}'
    
    for attempt in range(3):
        try:
            r = requests.get(url, proxies=PROXIES, timeout=60)
            r.raise_for_status()
            break
        except Exception as e:
            print(f"arXiv 请求失败 (尝试 {attempt+1}/3): {e}", file=sys.stderr)
            time.sleep(2)
    else:
        return []
    
    # 计算一周前的时间戳
    one_week_ago = datetime.now() - timedelta(days=7)
    
    root = ET.fromstring(r.text)
    ns = '{http://www.w3.org/2005/Atom}'
    
    papers = []
    for entry in root.findall(f'{ns}entry'):
        title_elem = entry.find(f'{ns}title')
        summary_elem = entry.find(f'{ns}summary')
        published_elem = entry.find(f'{ns}published')
        id_elem = entry.find(f'{ns}id')
        
        if any(e is None for e in [title_elem, summary_elem, published_elem, id_elem]):
            continue
        
        title_text = title_elem.text.strip() if title_elem.text else ''
        summary_text = summary_elem.text.strip() if summary_elem.text else ''
        published_text = published_elem.text.strip() if published_elem.text else ''
        arxiv_id_text = id_elem.text.strip() if id_elem.text else ''
        
        # 关键设计点：时间窗口过滤
        try:
            published_date = datetime.strptime(published_text[:19], '%Y-%m-%dT%H:%M:%S')
            if published_date < one_week_ago:
                continue  # 超过一周，跳过
        except ValueError:
            continue  # 日期格式异常，跳过
        
        authors = []
        for a in entry.findall(f'{ns}author'):
            name_elem = a.find(f'{ns}name')
            if name_elem is not None and name_elem.text:
                authors.append(name_elem.text.strip())
        
        papers.append({
            'title': title_text,
            'summary': summary_text[:500],
            'published': published_text,
            'arxiv_id': arxiv_id_text,
            'authors': authors[:5],
            'link': arxiv_id_text.replace('http://', 'https://')
        })
    
    return papers

def generate_review_prompt(papers):
    """生成审稿人 review 的 prompt"""
    papers_json = json.dumps(papers, ensure_ascii=False, indent=2)
    today = datetime.now().strftime('%Y年%m月%d日')
    
    prompt = f"""你是顶会（NeurIPS/ICML/ICLR/ACL）的严苛审稿人。请分析以下 arXiv 最新论文摘要，并给出筛选报告。

## ⚠️ 重要约束

1. **严格基于提供的摘要推理**：你只能根据下面提供的论文标题和摘要进行分析，不要编造论文中未提及的内容
2. **不要虚构细节**：如果摘要中没有提到实验数据、对比方法等，不要假设它们存在
3. **保持客观**：基于摘要中的技术描述和论证逻辑进行判断

## 分析标准

1. **陈旧架构**：识别使用过时技术栈、重复已有工作、缺乏创新点的论文
2. **颠覆性观点**：识别提出全新思路、挑战现有范式、有理论突破的论文
3. **扎实实验**：识别实验设计严谨、数据充分、对比充分的论文
4. **质量低下**：识别实验不足、论证薄弱、写作混乱的论文

## 输出格式

请严格按以下格式输出（不要输出其他内容）：

### ⭐ 值得关注的论文（3-5篇）
列出最有价值的论文，每篇包含：
- 标题 + arXiv ID
- 一句话评价（为什么值得关注）
- 创新点简述

### ⚠️ 勉强可看的论文（3-5篇）
- 标题 + arXiv ID
- 简短评价（优点和缺陷）

### ❌ 建议忽略的论文（5-8篇）
- 标题 + arXiv ID
- 一句话说明为什么质量低

### 📊 本周趋势总结
用 3-5 句话总结本周 AI 领域的整体趋势

---

以下是待分析的论文摘要（共 {len(papers)} 篇）：

{papers_json}
"""
    return prompt

def save_report(report, filepath='/tmp/arxiv_weekly_review.txt'):
    """保存报告到文件"""
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"报告已保存到: {filepath}")

def main():
    print("=" * 50)
    print("ArXiv 论文周报 - 顶会严苛审稿人版")
    print(f"日期: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print("=" * 50)
    
    # 1. 获取论文
    print("\n[1/3] 正在抓取 arXiv 论文...")
    papers = fetch_arxiv_papers('cs', 50)
    
    if not papers:
        print("未能获取论文数据，退出", file=sys.stderr)
        sys.exit(1)
    
    print(f"  获取到 {len(papers)} 篇最近 7 天更新的论文")
    
    # 2. 生成 prompt 并保存到临时文件
    prompt = generate_review_prompt(papers)
    prompt_path = '/tmp/arxiv_review_prompt.txt'
    with open(prompt_path, 'w', encoding='utf-8') as f:
        f.write(prompt)
    
    # 同时保存原始数据
    data_path = '/tmp/arxiv_papers.json'
    with open(data_path, 'w', encoding='utf-8') as f:
        json.dump(papers, f, ensure_ascii=False, indent=2)
    
    print(f"\n[2/3] 审稿人 prompt 已生成")
    print(f"  Prompt: {prompt_path}")
    print(f"  数据: {data_path}")
    
    # 3. 输出 prompt 供 cron job 的 agent 处理
    print("\n[3/3] 请 AI 审稿人分析以下论文...")
    print("\n" + "=" * 50)
    print(prompt)
    print("=" * 50)
    
    # 保存 prompt 供后续 cron job 使用
    print(f"\n--- 提示：cron job 读取 {prompt_path} 作为上下文 ---", file=sys.stderr)

if __name__ == '__main__':
    main()
