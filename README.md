# 《生物科学综合实验》人机协作课程建设方案 · 中山大学

课程建设方案的项目资料库。所有文档以 HTML / Markdown 纯文本形式保存，通过 Git 管理版本，
支持多设备接续编辑与在线预览。

## 在线预览

<https://dreamgitdeep.github.io/sysu-bio-comprehensive-experiment/>

推送到 GitHub 后约 1 分钟自动更新。

## 换一台电脑继续工作

```bash
# 1. 克隆（只需做一次）
git clone https://github.com/dreamgitdeep/sysu-bio-comprehensive-experiment.git

# 2. 每次开工前，先拉最新
git pull

# 3. 改完后提交推送
git add -A
git commit -m "本次改了什么"
git push
```

Windows 下可直接双击 **`sync.cmd "本次改了什么"`** 完成上面第 2、3 步。

## 本地预览

改完想先看效果，不用推送：

- **Windows**：双击 `preview.cmd`，浏览器自动打开 `http://localhost:8000`
- **其他系统**：在项目目录执行 `python -m http.server 8000`，访问 `http://localhost:8000`

> 单文件 HTML 也可以直接双击用浏览器打开，但用本地服务预览能确保图片相对路径正常加载。

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `index.html` | 导航首页（Pages 入口），新增文档时在此加一条链接 |
| `吴-项目方案交流文件.html` | 主方案演示文稿，自带翻页 / 全屏 / 导出 PDF |
| `内容大纲-待填清单.md` | 各章节内容缺口与待补充事项 |
| `素材文本/` | 原始素材：汇报 PPT、规划建议、诊断报告 |
| `versions/` | 历史快照，由 `deck.cmd snap` 生成，**不入库** |
| `preview.cmd` / `sync.cmd` | Windows 一键预览 / 一键同步脚本 |
| `deck.cmd` / `deck.ps1` | 演示文稿工具：体检、新增页面、存快照 |

## 新增文档

1. 把文件放进本目录
2. 在 `index.html` 的对应区块加一条链接
3. 执行 `sync.cmd "新增某某文档"`

## 注意事项

- `versions/`、`_原始备份.html`、`*滚动版备份.html` 已在 `.gitignore` 中排除，
  版本管理交给 Git 历史，不必重复入库。
- 演示文稿中若引用了新图片，图片文件需一并提交，否则线上预览会缺图。
