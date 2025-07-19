# Driver-Monitoring-System
A real-time driver drowsiness detection system using CNN-LSTM deep learning architecture, trained on NTHU, YAWDD, and custom datasets with video-based yawning recognition.

This project implements a real-time driver drowsiness detection system using a hybrid CNN-LSTM deep learning architecture. It classifies facial video frames to detect yawning — a key indicator of drowsiness — using spatial and temporal features. The model is trained and tested on three datasets: NTHU-DDD, YAWDD, and a custom video dataset. The system is designed to run in real time using standard webcams, and The model is deployed using a Flask backend and integrated with a Flutter mobile application, making it lightweight, portable, and accessible on smartphones. It can process real-time video locally.


## Key Features
- CNN-LSTM architecture for combining spatial and temporal features.
- Real-time yawning detection from video input.
- Frame sampling, and preprocessing pipeline.
- Tested on diverse datasets for robustness.
- Cost-efficient and non-intrusive implementation.
