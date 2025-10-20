# app.py
import streamlit as st
from PIL import Image, ImageEnhance, ImageFilter
import io, json, random

st.set_page_config(page_title="Mini Horse Stable", layout="centered")
st.title("🐎 Mini Horse Stable")

# 1) Horse image
img_file = st.file_uploader("Upload a horse photo (PNG/JPG)", type=["png", "jpg", "jpeg"])

# 2) Appearance tuning
st.subheader("Appearance")
col1, col2, col3, col4 = st.columns(4)
brightness = col1.slider("Brightness", 0.2, 2.0, 1.0, 0.05)
contrast   = col2.slider("Contrast",   0.2, 2.0, 1.0, 0.05)
color      = col3.slider("Color",      0.2, 2.0, 1.0, 0.05)
sharpness  = col4.slider("Sharpness",  0.2, 2.0, 1.0, 0.05)
blur = st.checkbox("Soft blur")

# 3) Stats
st.subheader("Stats")
name   = st.text_input("Horse name", "Comet")
speed  = st.slider("Speed",  1, 100, 70)
stam   = st.slider("Stamina",1, 100, 65)
jump   = st.slider("Jump",   1, 100, 60)

# 4) Preview
if img_file:
    img = Image.open(img_file).convert("RGB")
    img = ImageEnhance.Brightness(img).enhance(brightness)
    img = ImageEnhance.Contrast(img).enhance(contrast)
    img = ImageEnhance.Color(img).enhance(color)
    img = ImageEnhance.Sharpness(img).enhance(sharpness)
    if blur:
        img = img.filter(ImageFilter.GaussianBlur(1.2))
    st.image(img, caption=f"{name} (S:{speed} St:{stam} J:{jump})", use_column_width=True)

# 5) Save card (JSON + PNG)
st.subheader("Save")
if st.button("Save Horse Card") and img_file:
    card = {
        "name": name, "speed": speed, "stamina": stam, "jump": jump,
        "tuning": {"brightness": brightness, "contrast": contrast, "color": color, "sharpness": sharpness, "blur": blur}
    }
    st.download_button("Download stats.json",
                       data=json.dumps(card, indent=2), file_name=f"{name}_stats.json", mime="application/json")

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    st.download_button("Download image.png", data=buf.getvalue(), file_name=f"{name}.png", mime="image/png")

# 6) Quick race sim (pick two horses by typing stats or pasting JSON)
st.subheader("Quick Race (toy)")
left  = st.text_area("Horse A stats.json")
right = st.text_area("Horse B stats.json")
if st.button("Race!"):
    try:
        A = json.loads(left); B = json.loads(right)
        def score(h):
            # simple weighted score + randomness
            return 0.5*h["speed"] + 0.35*h["stamina"] + 0.15*h["jump"] + random.uniform(-10, 10)
        sA, sB = score(A), score(B)
        winner = A["name"] if sA >= sB else B["name"]
        st.success(f"🏁 Winner: {winner}  (A={sA:.1f}, B={sB:.1f})")
    except Exception as e:
        st.error("Paste valid JSON saved from this app to race two horses.")
