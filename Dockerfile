FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  git python3.11 python3.11-venv python3-pip \
  python3.11-dev build-essential ca-certificates \
  pkg-config ffmpeg libsndfile1 libsndfile1-dev \
  libavcodec-dev libavformat-dev libavdevice-dev libavutil-dev \
  libswresample-dev libswscale-dev \
  rustc cargo \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/xtts

RUN git clone --depth 1 https://github.com/daswer123/xtts-webui.git /opt/xtts

RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

RUN python -m pip install --no-cache-dir torch==2.1.1+cu118 torchaudio==2.1.1+cu118 --index-url https://download.pytorch.org/whl/cu118

# Устанавливаем зависимости без strict проверки
RUN python -m pip install --no-cache-dir --use-deprecated=legacy-resolver -r /opt/xtts/requirements.txt

EXPOSE 8010

WORKDIR /opt/xtts

CMD ["python", "app.py", "--device", "cuda", "--host", "0.0.0.0", "--port", "8010"]
