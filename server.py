from flask import Flask, request, send_file, jsonify
from gradio_client import Client, handle_file
import time
import os
import wave

app = Flask(__name__)

# Kết nối đến F5-TTS model trên Hugging Face
f5_client = Client("coutMinh/f5tts-vietnamese-v2")

# Tạo thư mục lưu audio
os.makedirs("audio_cache", exist_ok=True)

# Audio mẫu mặc định (giọng nữ tiếng Việt)
DEFAULT_REF_AUDIO = "ref_audio.wav"  # Bạn cần tự chuẩn bị file này
DEFAULT_REF_TEXT = "Xin chào, tôi là trợ lý ảo của bạn."

@app.route('/tts', methods=['POST'])
def text_to_speech():
    try:
        # Nhận dữ liệu từ client
        data = request.json
        text = data.get('text', '')
        speed = data.get('speed', 1.0)
        remove_silence = data.get('remove_silence', True)
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        print(f"[INFO] Processing text: {text}")
        start_time = time.time()
        
        # Gọi F5-TTS API
        result = f5_client.predict(
            ref_audio=handle_file(DEFAULT_REF_AUDIO),  # Audio giọng mẫu
            ref_text=DEFAULT_REF_TEXT,                 # Text của giọng mẫu
            gen_text=text,                              # Text cần đọc
            speed=speed,                                # Tốc độ đọc
            remove_silence=remove_silence,              # Xóa khoảng lặng
            api_name="/generate_speech"
        )
        
        processing_time = time.time() - start_time
        
        # result là đường dẫn đến file audio được generate
        audio_path = result
        
        # Tính RTF (Real-Time Factor)
        with wave.open(audio_path, 'rb') as wf:
            frames = wf.getnframes()
            rate = wf.getframerate()
            audio_duration = frames / float(rate)
        
        rtf = processing_time / audio_duration if audio_duration > 0 else 0
        
        print(f"[INFO] Processing time: {processing_time:.2f}s")
        print(f"[INFO] Audio duration: {audio_duration:.2f}s")
        print(f"[INFO] RTF: {rtf:.3f}")
        
        # Trả về file audio
        return send_file(
            audio_path,
            mimetype='audio/wav',
            as_attachment=False,
            download_name='speech.wav'
        )
    
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/tts-custom', methods=['POST'])
def text_to_speech_custom():
    """
    API với khả năng clone giọng từ audio upload
    """
    try:
        # Nhận files và data
        if 'ref_audio' not in request.files:
            return jsonify({'error': 'No reference audio provided'}), 400
        
        ref_audio_file = request.files['ref_audio']
        ref_text = request.form.get('ref_text', '')
        gen_text = request.form.get('gen_text', '')
        speed = float(request.form.get('speed', 1.0))
        remove_silence = request.form.get('remove_silence', 'true').lower() == 'true'
        
        if not gen_text:
            return jsonify({'error': 'No text to generate'}), 400
        
        # Lưu audio tạm
        temp_audio_path = os.path.join("audio_cache", f"temp_{int(time.time())}.wav")
        ref_audio_file.save(temp_audio_path)
        
        print(f"[INFO] Custom voice - Processing text: {gen_text}")
        start_time = time.time()
        
        # Gọi F5-TTS với audio tùy chỉnh
        result = f5_client.predict(
            ref_audio=handle_file(temp_audio_path),
            ref_text=ref_text,
            gen_text=gen_text,
            speed=speed,
            remove_silence=remove_silence,
            api_name="/generate_speech"
        )
        
        processing_time = time.time() - start_time
        print(f"[INFO] Processing time: {processing_time:.2f}s")
        
        # Xóa file tạm
        os.remove(temp_audio_path)
        
        return send_file(
            result,
            mimetype='audio/wav',
            as_attachment=False,
            download_name='custom_speech.wav'
        )
    
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'ok',
        'model': 'F5-TTS Vietnamese V2',
        'endpoints': ['/tts', '/tts-custom']
    })

if __name__ == '__main__':
    # Kiểm tra file audio mẫu
    if not os.path.exists(DEFAULT_REF_AUDIO):
        print("[WARNING] Default reference audio not found!")
        print("[INFO] Please add 'ref_audio.wav' file or the API will fail.")
    
    print("[INFO] Starting F5-TTS Server...")
    app.run(host='0.0.0.0', port=5000, debug=False)