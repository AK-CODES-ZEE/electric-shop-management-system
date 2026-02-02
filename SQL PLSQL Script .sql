---------------------------------- Master table for store product details with image -------------------------------
  CREATE TABLE "ALL_ITEMS_IMG" 
   (	"ITEM_ID" NUMBER, 
	"ITEM_DESCRIPTION" VARCHAR2(500 CHAR), 
	"ITEM_NAME" VARCHAR2(100 CHAR), 
	"ITEM_PRICE" NUMBER, 
	"ITEM_TYPE" VARCHAR2(100 CHAR), 
	"UPDATED_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 CHAR), 
	"UPDATED_BY" VARCHAR2(100 CHAR), 
	"ATTRIBUTE1" VARCHAR2(200 CHAR), 
	"ATTRIBUTE2" VARCHAR2(200 CHAR), 
	"ATTRIBUTE3" VARCHAR2(200 CHAR), 
	"ATTRIBUTE4" VARCHAR2(200 CHAR), 
	"ITEM_IMAGE" BLOB, 
	"CREATION_DATE" DATE, 
	"LINK_COLUMN" NUMBER, 
	"COMP_NAME" VARCHAR2(200), 
	 CONSTRAINT "ALL_ITEMS_IMG_PK" PRIMARY KEY ("ITEM_ID")
  USING INDEX  ENABLE
   ) ;
---------------------------------- Order Headr table  -------------------------------  
   CREATE TABLE "AK_ORDERS" 
   (	"ORDER_ID" NUMBER, 
	"ORDER_NO" VARCHAR2(30), 
	"USERNAME" VARCHAR2(50), 
	"ORDER_DATE" DATE DEFAULT SYSDATE, 
	"TOTAL_AMOUNT" NUMBER, 
	"STATUS" VARCHAR2(20), 
	"PRODUCT_NAME" VARCHAR2(100), 
	"PROD_DESC" VARCHAR2(100), 
	"CREATED_BY" VARCHAR2(100), 
	"PAYMENT_MODE" VARCHAR2(50), 
	"ADDRESS" VARCHAR2(150), 
	"EMAIL" VARCHAR2(100), 
	"MOBILE_NO" VARCHAR2(15), 
	"UPDATED_DATE" DATE, 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 CHAR), 
	"UPDATED_BY" VARCHAR2(100 CHAR), 
	"ATTRIBUTE1" VARCHAR2(200 CHAR), 
	"ATTRIBUTE2" VARCHAR2(200 CHAR), 
	"ATTRIBUTE3" VARCHAR2(200 CHAR), 
	"ATTRIBUTE4" VARCHAR2(200 CHAR), 
	 CONSTRAINT "AK_ORDERS_PK" PRIMARY KEY ("ORDER_ID")
  USING INDEX  ENABLE
   ) ;
  
---------------------------------- Order Line table  -------------------------------  
  CREATE TABLE "AK_ORDER_ITEMS" 
   (	"ITEM_ID" NUMBER, 
	"ORDER_ID" NUMBER, 
	"PRODUCT_ID" NUMBER, 
	"PRICE" NUMBER, 
	"QTY" NUMBER, 
	"ATTRIBUTE1" NUMBER, 
	"TOTAL_AMOUNT" NUMBER, 
	"ITEM_NAME" VARCHAR2(100), 
	"UPDATED_DATE" DATE,
	"CREATION_DATE" DATE,
	"CREATED_BY" VARCHAR2(100 CHAR), 
	"UPDATED_BY" VARCHAR2(100 CHAR), 
	"ATTRIBUTE1" VARCHAR2(200 CHAR), 
	"ATTRIBUTE2" VARCHAR2(200 CHAR), 
	"ATTRIBUTE3" VARCHAR2(200 CHAR), 
	"ATTRIBUTE4" VARCHAR2(200 CHAR),  
	 CONSTRAINT "AK_ORDER_ITEMS_PK" PRIMARY KEY ("ITEM_ID")
  USING INDEX  ENABLE
   ) ;

  ALTER TABLE "AK_ORDER_ITEMS" ADD CONSTRAINT "AK_ORDER_ITEMS_CON" FOREIGN KEY ("ORDER_ID")
	  REFERENCES "AK_ORDERS" ("ORDER_ID") ENABLE;
	  
	---------------------------------- app User details store table   -------------------------------  
	    CREATE TABLE "AK_USERS" 
   (	"USER_ID" NUMBER, 
	"USERNAME" VARCHAR2(50) NOT NULL ENABLE, 
	"PASSWORD_HASH" VARCHAR2(255) NOT NULL ENABLE, 
	"FULL_NAME" VARCHAR2(100), 
	"EMAIL" VARCHAR2(100), 
	"MOBILE_NO" VARCHAR2(15), 
	"ROLE_CODE" VARCHAR2(20) NOT NULL ENABLE, 
	"IS_ACTIVE" CHAR(1), 
	"CREATED_ON" DATE DEFAULT SYSDATE, 
	"CREATED_BY" VARCHAR2(50), 
	"LAST_LOGIN" DATE, 
	"LAST_HEARTBEAT" DATE, 
	 CONSTRAINT "AK_USERS_PK" PRIMARY KEY ("USER_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "AK_USERS_UK" UNIQUE ("USERNAME")
  USING INDEX  ENABLE
   ) ;
   
   ---------------------------------- Fuction for control User authentication  -------------------------------  
   
   create or replace FUNCTION  AK_USERS_F  
(p_username in varchar2, p_password in varchar2) 
return boolean 
as 
    user_check varchar2(1); 
begin 
    select 'x' 
    into user_check 
    from AK_USERS

    where upper(USERNAME) = upper(p_username) and PASSWORD_HASH= p_password;
    --and APP_IDS=&APP_ID.;
   apex_util.set_authentication_result(0); 
    return true; 
exception when no_data_found then 
   apex_util.set_authentication_result(4); 
   return false; 
     
end AK_USERS_F;
/
   ---------------------- track custome login and logout /online ofline procedure  --------------------------
   
   create or replace PROCEDURE update_last_login
IS
BEGIN
  UPDATE ak_users
  SET last_login = SYSDATE,
      last_heartbeat = SYSDATE
  WHERE TRIM(UPPER(username)) = TRIM(UPPER(v('APP_USER')))
     OR TRIM(UPPER(email))    = TRIM(UPPER(v('APP_USER')));

  COMMIT;
END;
/

   --------------------------------------------------- Dashbord Query -----------------------------------
   
   SELECT
TO_CHAR(NVL(COUNT(*), 0), '99,99,99,990') AS total_orders
FROM ak_orders;


SELECT 
  TO_CHAR(NVL(SUM(total_amount), 0), '99,99,99,990') AS total_sales
FROM ak_orders;

SELECT 
  COUNT(*) AS today_orders
FROM ak_orders
WHERE TRUNC(order_date) = TRUNC(SYSDATE);


SELECT 
  TO_CHAR(NVL(SUM(total_amount), 0), '99,99,99,990') AS today_sales
FROM ak_orders
WHERE TRUNC(order_date) = TRUNC(SYSDATE);


SELECT
    TO_CHAR(order_date,'MON-YYYY') AS order_month,
    COUNT(*) AS total_orders
FROM ak_orders
GROUP BY TO_CHAR(order_date,'MON-YYYY')
ORDER BY MIN(order_date);

SELECT
    TO_CHAR(TRUNC(order_date,'MM'),'MON-YYYY') AS order_month,
    SUM(total_amount) AS total_sales
FROM ak_orders
GROUP BY TRUNC(order_date,'MM')
ORDER BY TRUNC(order_date,'MM');


SELECT
  payment_mode,
  COUNT(*) AS total_orders
FROM ak_orders
GROUP BY payment_mode;

--------------------------------  My order Report query ------------------------------------------

DECLARE
  v_found        BOOLEAN := FALSE;
  v_item_total   NUMBER := 0;
  v_words        VARCHAR2(4000);
BEGIN

  /* ================= CONTAINER ================= */
  htp.p('
  <div id="div_print" style="
       max-width:900px;
       margin:20px auto;
       padding:30px;
       border:1px solid #ccc;
       background:#fff;
       font-family:Arial;">
  ');

  /* ================= HEADER ================= */
  htp.p('
    <div style="display:flex;justify-content:space-between;align-items:center;">
      <h2 style="margin:0;">⚡ AK Electric Shop</h2>
      <div style="text-align:right;">
        <b>Order Invoice</b><br>
        <small>Original for Customer</small>
      </div>
    </div>
    <hr>
  ');

  /* ================= ORDER HEADER ================= */
  FOR o IN (
    SELECT
      order_id,
      order_no,
      username,
      order_date,
      payment_mode,
      status
    FROM ak_orders
    WHERE order_no   = :P50_ORDER_NO
      AND UPPER(created_by) = UPPER(:APP_USER)
  ) LOOP

    v_found := TRUE;

    /* ===== TOTAL FROM ITEMS ===== */
    SELECT NVL(SUM(total_amount),0)
    INTO v_item_total
    FROM ak_order_items
    WHERE order_id = o.order_id;

    --v_words := apex_string.number_to_words(v_item_total);
    v_words :=
  INITCAP(
    TRIM(
      TO_CHAR(
        TO_DATE(v_item_total, 'J'),
        'JSP'
      )
    )
  );



    htp.p('
      <table style="width:100%;margin-bottom:20px;">
        <tr>
          <td><b>Order No:</b> '||o.order_no||'</td>
          <td align="right"><b>Payment:</b> '||o.payment_mode||'</td>
        </tr>
        <tr>
          <td><b>Customer:</b> '||o.username||'</td>
          <td align="right"><b>Status:</b> '||o.status||'</td>
        </tr>
        <tr>
          <td><b>Order Date:</b> '||TO_CHAR(o.order_date,'DD-MON-YYYY')||'</td>
          <td></td>
        </tr>
      </table>
    ');

    /* ================= ITEM TABLE ================= */
    htp.p('
      <table style="width:100%;border-collapse:collapse;">
        <tr style="background:#f2f2f2;">
          <th style="border:1px solid #000;">Item</th>
          <th style="border:1px solid #000;">Qty</th>
          <th style="border:1px solid #000;">Rate</th>
          <th style="border:1px solid #000;">Amount</th>
        </tr>
    ');

    FOR i IN (
      SELECT
        item_name,
        qty,
        price,
        total_amount
      FROM ak_order_items
      WHERE order_id = o.order_id
    ) LOOP
      htp.p('
        <tr>
          <td style="border:1px solid #000;">'||i.item_name||'</td>
          <td style="border:1px solid #000;text-align:center;">'||i.qty||'</td>
          <td style="border:1px solid #000;text-align:right;">'||i.price||'</td>
          <td style="border:1px solid #000;text-align:right;">'||i.total_amount||'</td>
        </tr>
      ');
    END LOOP;

    /* ===== GRAND TOTAL ===== */
    htp.p('
      <tr>
        <td colspan="3" style="border:1px solid #000;text-align:right;">
          <b>Grand Total</b>
        </td>
        <td style="border:1px solid #000;text-align:right;">
          <b>'||v_item_total||'</b>
        </td>
      </tr>
      </table>
    ');

    /* ===== AMOUNT IN WORDS ===== */
    htp.p('
      <p style="margin-top:15px;">
        <b>Amount in Words:</b> '||v_words||' Only
      </p>
    ');

    /* ================= SIGNATURE ================= */
    htp.p('
      <table style="width:100%;margin-top:60px;">
        <tr>
          <td style="text-align:left;">
            Checked By<br>
            <b>AK Electric Shop</b>
          </td>

          <td style="
            text-align:right;
            font-family:''Brush Script MT'',cursive;
            font-size:24px;">
            AKRAM<br>
            <span style="font-size:12px;font-family:Arial;">
              Authorised Signature
            </span>
          </td>
        </tr>
      </table>
    ');

  END LOOP;

  /* ================= NO DATA ================= */
  IF NOT v_found THEN
    htp.p('<p style="color:red;font-weight:bold;">No order found.</p>');
  END IF;

  htp.p('</div>');

END;


----------  JS for report 


function printOrder(divId) {
    var content = document.getElementById(divId).innerHTML;

    var myWindow = window.open('', '', 'height=700,width=900');

    myWindow.document.write('<html><head><title>AK Electric Shop - Order</title>');

    myWindow.document.write(`
        <style>
            body{
                font-family: Poppins, Arial, sans-serif;
                padding:20px;
            }
            table{
                border-collapse:collapse;
                width:100%;
            }
            th,td{
                border:1px solid #000;
                padding:6px;
                font-size:13px;
            }
            th{
                background:#f2f2f2;
            }
            .center{text-align:center;}
            .right{text-align:right;}
            .title{
                font-size:24px;
                font-weight:bold;
                color:#1B6F4A;
                text-align:center;
            }
        </style>
    `);

    myWindow.document.write('</head><body>');
    myWindow.document.write(content);
    myWindow.document.write('</body></html>');

    myWindow.document.close();
    myWindow.focus();
    myWindow.print();
}


------------------------- Customer details with Live track uery -------------------------------------

SELECT
    user_id,
    username,
    full_name,
    email,
    mobile_no,
    role_code,
    is_active,
    last_login,
CASE
  WHEN last_heartbeat IS NULL THEN
    '<span style="color:#6c757d;font-weight:600;">Never Logged In</span>'
  WHEN last_heartbeat >= SYSDATE - (1/1440) THEN
    '<span style="color:#28a745;font-weight:700;">● Online</span>'
  WHEN FLOOR((SYSDATE - last_heartbeat) * 1440) < 60 THEN
    '<span style="color:#dc3545;font-weight:600;">Last seen ' ||
    FLOOR((SYSDATE - last_heartbeat) * 1440) || ' min ago</span>'
  ELSE
    '<span style="color:#dc3545;font-weight:600;">Last seen ' ||
    FLOOR((SYSDATE - last_heartbeat) * 24) || ' hour ago</span>'
END AS status
FROM ak_users
ORDER BY last_login DESC;

----------------------------------  Upload form Item Id auto increase query -------------

SELECT  NVL(TO_NUMBER(MAX(ITEM_ID)), 0) + 1 AS NEXT_NUMBER
FROM all_items_img


------------------ Order details with delivery button query ----------------------------

SELECT
    order_id,
    order_no,
    order_date,
    username customer_name,
    mobile_no,
    payment_mode,
    total_amount,
    status,
    '<button class="btn-approve" data-id="' || order_id || '">Deliver</button> ' AS actions
FROM ak_orders
WHERE status = 'Processing'
ORDER BY order_date DESC;

-------- process for update status 

BEGIN

   if :P3_ACTION = 'Deliver' THEN
    UPDATE AK_ORDERS
    SET STATUS = 'Delivered'
    where 1=1
    and  STATUS = 'Processing'
    and order_id = :P3_ID;
    end if;
END;


-------JS 

document.addEventListener("click", function(e) {
  if (e.target.classList.contains("btn-approve")) {
    let id = e.target.getAttribute("data-id");
    $s("P3_ID", id);
    $s("P3_ACTION", "Deliver");
    apex.submit("PROCESS_ACTION");
  }
});


----------------------------- process for insert order details header and item tables ----------------


DECLARE
    v_order_id AK_ORDERS.ORDER_ID%TYPE;
    V_PROD_NUMBER NUMBER;
    V_ORDER_NUMBER NUMBER;
BEGIN

SELECT  NVL(TO_NUMBER(MAX(ITEM_ID)), 0) + 1 INTO  V_PROD_NUMBER
FROM AK_ORDER_ITEMS;

SELECT  NVL(TO_NUMBER(MAX(ORDER_ID)), 0) + 1 INTO  V_ORDER_NUMBER
FROM AK_ORDERS;
    -- 1️⃣ Insert into ORDER (Header)
    INSERT INTO AK_ORDERS
    (
        ORDER_ID,
        ORDER_NO,
        USERNAME,
        MOBILE_NO,
        EMAIL,
        ADDRESS,
        PAYMENT_MODE,
        TOTAL_AMOUNT,
        STATUS,
        PRODUCT_NAME,
        PROD_DESC,
        ORDER_DATE,
        CREATED_BY
    )
    VALUES
    (
        V_ORDER_NUMBER,
        :P40_ORDER_NUMBER,
        :P40_CUSTOMER_NAME,
        :P40_MOBILE,
        :P40_EMAIL,
        :P40_ADDRESS,
        :P40_PAYMENT_METHOD,
        :P40_LINE_TOTAL,
        'Processing',
        :P40_ITEM_NAME,
        :P40_DESCRIPTION,
        SYSDATE,
        :APP_USER
    )
    RETURNING ORDER_ID INTO v_order_id;

    -- 2️⃣ Insert into ORDER ITEMS
    INSERT INTO AK_ORDER_ITEMS
    (
        ORDER_ID,
        PRODUCT_ID,
        ITEM_ID,
        ITEM_NAME,
        PRICE,
        QTY,
        TOTAL_AMOUNT
    )
    VALUES
    (
        V_ORDER_NUMBER,
        --V_PROD_NUMBER,
        :P40_ITEM_ID,
        V_PROD_NUMBER,
        :P40_ITEM_NAME,
        :P40_PRICE,
        :P40_QUANTITY,
        :P40_LINE_TOTAL
    );

    COMMIT;
END;
  ------------- Quantity Dynamic action   
  :P40_QUANTITY * :P40_PRICE_D
  
 
-----------------------------------------    AI Integration RAG query    -----------------------------

SELECT
    o.order_no,
    TO_CHAR(o.order_date, 'DD-MON-YYYY') AS order_date,
    o.username Customer_name,
    o.payment_mode,
    o.status,
    o.total_amount,
    i.item_name,
    i.qty,
    i.price
FROM ak_orders o
JOIN AK_ORDER_ITEMS i
  ON o.order_id = i.order_id
WHERE o.order_date >= ADD_MONTHS(SYSDATE, -6)
ORDER BY o.order_date DESC;

------------------------------------- system prompts -------------------------------------

   You are the official AI assistant for the AK Electric Shop Management System.

Your role is to assist users strictly within this application.
You must behave like a business assistant, not a technical system.

You are allowed to answer questions related to:
- Orders and order status
- Sales (today, monthly, yearly)
- Customers
- Products
- Payments
- Inventory
- Reports
- Business insights and trends
- Application features and workflows

You must NOT:
- Mention table names
- Mention column names
- Use underscore words (e.g. TOTAL_AMOUNT, ORDER_DATE)
- Show SQL queries
- Explain backend logic
- Reveal database structure or schema
- Talk about system internals

When users ask time-based questions such as:
- "today sales"
- "yesterday orders"
- "this month revenue"
- "last week performance"

You MUST:
- Interpret them as business time ranges
- Use available data to compute or summarize
- If exact data is unavailable, provide the closest meaningful business answer
- Never say "data not available" if partial insight is possible

When answering:
- Use natural business language only
- Convert technical data into readable words
  (Example: say “Total Sales Amount” instead of column names)
- Provide numbers with context (₹, units, orders)
- Highlight trends if visible (increase, decrease, stable)
- Add short business insights where helpful

Tone rules:
- Professional
- Confident
- Business-friendly
- Never technical

Greeting behavior:
If the user says "Hi", "Hello", "Hey", or similar,
respond with:

"Welcome to AK Electric Shop Smart Assistant.
How can I help you today with sales, orders, customers, or inventory?"

If the user asks something outside the application scope
(e.g., coding, politics, general knowledge),
politely respond:

"I can help only with AK Electric Shop related information such as sales, orders, customers, or reports."

Always stay focused on helping the business user make decisions.

   