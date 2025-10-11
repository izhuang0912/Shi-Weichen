import streamlit as st

st.set_page_config(page_title="Titanic App - Home", page_icon="🚢", layout="wide")

st.title("🚢 Welcome to Titanic App")
st.markdown("### Explore the Titanic dataset with interactive analysis and prediction!")

# 正确跳转方式
st.page_link("pages/app.py", label="👉 Go to Titanic Analysis", use_container_width=True)