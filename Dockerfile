FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
  git ca-certificates curl build-essential \
  python3.11 python3.11-venv python3.11-dev python3-pip \
  ffmpeg libsndfile1 libsndfile1-dev \
  libavcodec-dev libavformat-dev libavdevice-dev libavutil-dev \
  libswresample-dev libswscale-dev \
  rustc cargo ninja-build \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/xtts

# Клонируем репозиторий
RUN git clone --depth 1 https://github.com/daswer123/xtts-webui.git /opt/xtts

# Создаём виртуальное окружение
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Апгрейдим pip
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Фиксим numpy <2 для совместимости с другими пакетами
RUN python -m pip install --no-cache-dir "numpy<2"

# PyTorch и torchaudio под CUDA 11.8
RUN python -m pip install --no-cache-dir \
  torch==2.1.1+cu118 torchaudio==2.1.1+cu118 --index-url https://download.pytorch.org/whl/cu118

# Совместимые версии пакетов для coqui-tts
RUN python -m pip install --no-cache-dir "transformers>=4.42.0,<4.43.0" "spacy<3.8"

# Устанавливаем зависимости проекта
RUN python -m pip install --no-cache-dir --use-deprecated=legacy-resolver -r /opt/xtts/requirements.txt

# Фиксируем совместимые версии gradio для исправления бага
RUN python -m pip install --no-cache-dir --force-reinstall gradio==4.29.0 gradio-client==0.16.1

# Копируем скрипт для патчинга
COPY patch_gradio.py /tmp/patch_gradio.py

# Патчим баг в gradio_client/utils.py
RUN python /tmp/patch_gradio.py /opt/venv/lib/python3.11/site-packages/gradio_client/utils.py

# Дополнительные пакеты безопасности
RUN python -m pip install --no-cache-dir requests pyyaml

# Создаём необходимые директории
RUN mkdir -p /opt/xtts/models /opt/xtts/output /opt/xtts/config /opt/xtts/speakers

WORKDIR /opt/xtts

EXPOSE 8010

# Команда запуска
CMD ["python", "app.py", "--device", "cuda", "--host", "0.0.0.0", "--port", "8010"]


