import streamlit as st
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# 1. Seaborn 风格
sns.set_style("whitegrid")

# 2. 页面标题
st.title("Titanic App by Your Name")   # 替换成自己的名字

# 3. 读取数据
df = pd.read_csv("train.csv")

# 4. 显示完整数据表
st.subheader("Training Dataset")
st.dataframe(df)

# 5. 绘制三张子图（15×5），Fare 按 Pclass 分布
st.subheader("Fare Distribution by Passenger Class")

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
classes = sorted(df["Pclass"].unique())

for ax, pc in zip(axes, classes):
    sns.boxplot(
        x="Pclass",
        y="Fare",
        data=df[df["Pclass"] == pc],
        ax=ax
    )
    ax.set_title(f"Pclass {pc}")
    ax.set_xlabel("Pclass")
    ax.set_ylabel("Fare")

plt.tight_layout()
st.pyplot(fig)