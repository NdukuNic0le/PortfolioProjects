#!/usr/bin/env python
# coding: utf-8

# In[9]:


# VISUALIZATION OF EXCEL DATA USING PLOTLY EXPRESS

import pandas as pd
import numpy as np
import plotly.express as px #for the visualiaztions
import streamlit as st


# In[8]:
st.set_page_config(page_title="Sales Dashboard",
                  page_icon= ":bar_chart:",
                  layout= "wide"
)

@st.cache
def get_data_from_excel():
    sales_df= pd.read_excel(
        io="Supermarkt_sales.xlsx",
        engine="openpyxl",
        sheet_name="Sales",
        skiprows=3,
        usecols="B:R",
        nrows=1000,
        )
    # Add 'hour' column to dataframe
    sales_df["hour"] = pd.to_datetime(sales_df["Time"], format="%H:%M:%S").dt.hour
    return sales_df

sales_df = get_data_from_excel()


# In[12]:





# ---- SIDEBAR ----
st.sidebar.header("Please Filter Here:")
city = st.sidebar.multiselect(
    "Select The City:",
    options=sales_df["City"].unique(),
    default=sales_df["City"].unique()
)

st.sidebar.header("Please Filter Here:")
customer_type = st.sidebar.multiselect(
    "Select The Customer Type:",
    options=sales_df["Customer_type"].unique(),
    default=sales_df["Customer_type"].unique()
)

st.sidebar.header("Please Filter Here:")
gender = st.sidebar.multiselect(
    "Select The Gender:",
    options=sales_df["Gender"].unique(),
    default=sales_df["Gender"].unique()
)

# Store the filtered data set in a variable

sales_df_selection= sales_df.query("City == @city & Customer_type == @customer_type & Gender == @gender"
)


#---- MAINPAGE ----

st.title(":bar_chart: Sales Dashboard")
st.markdown("##")

# TOP KPI's

total_sales = int(sales_df_selection["Total"].sum())
average_rating = round(sales_df_selection["Rating"].mean(), 1)
star_rating = ":star:" * int(round(average_rating, 0))
average_sale_by_transaction = round(sales_df_selection["Total"].mean(), 2)

left_column, middle_column, right_column = st.columns(3)
with left_column:
    st.subheader("Total Sales:")
    st.subheader(f"US $ {total_sales:,}")
with middle_column:
    st.subheader("Average Rating:")
    st.subheader(f"{average_rating} {star_rating}")
with right_column:
    st.subheader("Average Sales Per Transaction:")
    st.subheader(f"US $ {average_sale_by_transaction}")

st.markdown("""---""")

# SALES BY PRODUCT LINE [BAR CHART]

sales_by_product_line = (
    sales_df_selection.groupby(by=["Product line"]).sum()[["Total"]].sort_values(by="Total")
)
fig_product_sales = px.bar(
    sales_by_product_line,
    x="Total",
    y=sales_by_product_line.index,
    orientation="h",
    title="<b>Sales by Product Line</b>",
    color_discrete_sequence=["#0083B8"] * len(sales_by_product_line),
    template="plotly_white",
)
fig_product_sales.update_layout(
    plot_bgcolor="rgba(0,0,0,0)",
    xaxis=(dict(showgrid=False))
)



# SALES BY HOUR [BAR CHART]

sales_by_hour =( 
    sales_df_selection.groupby(by=["hour"]).sum()[["Total"]]
)
fig_hourly_sales = px.bar(
    sales_by_hour,
    x=sales_by_hour.index,
    y="Total",
    title="<b>Sales by hour</b>",
    color_discrete_sequence=["#0083B8"] * len(sales_by_hour),
    template="plotly_white",
)
fig_hourly_sales.update_layout(
    xaxis=dict(tickmode="linear"),
    plot_bgcolor="rgba(0,0,0,0)",
    yaxis=(dict(showgrid=False)),
)

left_column, right_column = st.columns(2)
left_column.plotly_chart(fig_hourly_sales, use_container_width=True)
right_column.plotly_chart(fig_product_sales, use_container_width=True)

# ---- HIDE STREAMLIT STYLE ----
hide_st_style = """
            <style>
            #MainMenu {visibility: hidden;}
            footer {visibility: hidden;}
            header {visibility: hidden;}
            </style>
            """
st.markdown(hide_st_style, unsafe_allow_html=True)





