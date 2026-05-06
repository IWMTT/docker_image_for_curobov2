# cuRobo Motion Planning + Jupyter Docker Image

このリポジトリは、cuRobo の公式ドキュメントにあるモーションプランニングのインタラクティブ例を、Runpod で使いやすい形にまとめた Docker 構成です。

コンテナ起動後に次の 2 つへアクセスできます。

- `http://<host>:8080`: cuRobo の `motion_planning --visualize`
- `http://<host>:8888`: Jupyter Notebook

対象ドキュメント:

- Installation: https://nvlabs.github.io/curobo/latest/getting-started/installation.html
- Motion Planning: https://nvlabs.github.io/curobo/latest/getting-started/motion_planning.html

## 1. 前提条件

- NVIDIA GPU を搭載した Linux ホスト、または Docker Desktop + WSL2 など Linux コンテナを GPU 付きで実行できる環境
- NVIDIA Container Toolkit が導入済みで、`docker run --gpus all ...` が利用可能
- Docker が利用可能
- Runpod で使う場合は、HTTP ポート `8080` と `8888` を公開する設定にすること
- ホストの NVIDIA Driver が cuRobo 最新 docs の要件を満たすこと
  - 2026-05-06 時点の最新 docs では `NVIDIA Driver >= 580.65.06`、CUDA 12 以上対応が要件

## 2. このイメージの方針

- ベースイメージ: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- Python: ベースイメージ付属の Python 3.11
- cuRobo: `v0.8.0` をソースからインストール
- インストール方式: 公式 Installation ページに沿って `uv` で `.[cu12-torch]` を導入
- Jupyter: `0.0.0.0:8888` で待ち受け
- Motion Planning Viewer: `0.0.0.0:8080` で待ち受け
- 起動時に Jupyter をバックグラウンド、cuRobo viewer をフォアグラウンドで同時起動

必要に応じて build 引数で切り替えできます:

- `BASE_IMAGE`: ベースイメージ
- `CUROBO_REF`: cuRobo のタグやブランチ
- `CUROBO_EXTRA`: `cu12-torch` / `cu13-torch` など

## 3. ビルド

リポジトリ直下で実行:

```bash
docker build -t YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0 .
```

タグをローカル確認用に簡単にしたい場合:

```bash
docker build -t curobo-motion-planning:local .
```

CUDA 13 系ベースに切り替える場合の例:

```bash
docker build \
  --build-arg BASE_IMAGE=YOUR_MATCHING_RUNPOD_OR_CUDA13_BASE_IMAGE \
  --build-arg CUROBO_EXTRA=cu13-torch \
  -t curobo-motion-planning:cu13 .
```

## 4. 実行

Linux/macOS の例:

```bash
docker run --rm -it \
  --gpus all \
  -p 8888:8888 \
  -p 8080:8080 \
  YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0
```

Windows PowerShell の例:

```powershell
docker run --rm -it `
  --gpus all `
  -p 8888:8888 `
  -p 8080:8080 `
  YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0
```

起動後、ブラウザで以下へアクセス:

```text
http://localhost:8080
http://localhost:8888
```

`8080` 側では以下を試せます:

- ターゲットフレームをドラッグして目標姿勢を変更
- 障害物をドラッグして配置変更
- `Move` ボタンで姿勢到達モーションを生成
- `Grasp` ボタンで approach / grasp / lift の3段階動作を生成

`8888` 側では Jupyter Notebook を開いて、`/workspace` 配下でノートブックを作成できます。

## 5. 環境変数

必要なら起動時に以下を上書きできます。

- `VISER_PORT`: cuRobo viewer のポート。既定値 `8080`
- `JUPYTER_PORT`: Jupyter のポート。既定値 `8888`
- `JUPYTER_HOST`: Jupyter の bind address。既定値 `0.0.0.0`
- `NOTEBOOK_DIR`: Jupyter の作業ディレクトリ。既定値 `/workspace`
- `JUPYTER_TOKEN`: Jupyter の token。既定値は空文字

例:

```bash
docker run --rm -it \
  --gpus all \
  -p 8080:8080 \
  -p 8888:8888 \
  -e JUPYTER_TOKEN=my-secret-token \
  YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0
```

## 6. Runpod での利用

Runpod にこのイメージを上げる場合は、Pod 作成時に少なくとも次を設定します。

- Container image: `YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0`
- Expose HTTP Ports: `8080,8888`
- GPU を有効化

起動後のアクセス先:

- `https://[runpod の 8080 公開 URL]`: cuRobo motion planning viewer
- `https://[runpod の 8888 公開 URL]`: Jupyter Notebook

Jupyter を公開インターネット越しに使うなら、`JUPYTER_TOKEN` を必ず設定してください。

## 7. 補足

- cuRobo 側のインタラクティブ viewer は実装上 `connect_ip="0.0.0.0"` で待ち受けるため、Runpod のような外部アクセス前提でも使いやすい構成です。
- このイメージの既定 `ENTRYPOINT` は Jupyter と viewer の同時起動用です。単発で `motion_planning --mode pose` のような CLI 実行に差し替えたい場合は `--entrypoint` で上書きしてください。
- build 時点では GPU を使わず Python import までを確認し、実際の motion planning は `docker run --gpus all` で行います。

CLI のみを単発で実行する例:

```bash
docker run --rm -it \
  --gpus all \
  --entrypoint python3 \
  YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0 \
  -m curobo.examples.getting_started.motion_planning --mode pose
```

## 8. Docker Hub へアップロード

`YOUR_DOCKERHUB_USER` を自分の Docker Hub ユーザー名に置き換えてください。

1. Docker Hub にログイン

```bash
docker login
```

2. イメージをビルド

```bash
docker build -t YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0 .
```

3. `latest` タグも付ける

```bash
docker tag YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0 YOUR_DOCKERHUB_USER/curobo-motion-planning:latest
```

4. Push

```bash
docker push YOUR_DOCKERHUB_USER/curobo-motion-planning:v0.8.0
docker push YOUR_DOCKERHUB_USER/curobo-motion-planning:latest
```
