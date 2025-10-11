import streamlit as st

# 必须放在第一条 Streamlit 命令
st.set_page_config(
    page_title="Titanic App - Home",
    page_icon="🚢",
    layout="wide"
)

st.title("🚢 Welcome to Titanic App")
st.markdown("""
### Explore the Titanic dataset with interactive analysis and prediction!

👈 You can navigate to the **App** page via the sidebar  
or use the button below to jump directly to the analysis.
""")

# 添加跳转到 app.py 的按钮
if st.button("Go to Titanic Analysis"):
    st.switch_page("app.py")