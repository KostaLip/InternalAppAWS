import json
import os
import csv
import io
import boto3
import psycopg2

s3 = boto3.client("s3")

def get_db_password():
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])
    return response["SecretString"]

def handler(event, context):
    try:
        source_bucket = event["Records"][0]["s3"]["bucket"]["name"]
        source_key    = event["Records"][0]["s3"]["object"]["key"]

        print(f"Obrada fajla: s3://{source_bucket}/{source_key}")

        response = s3.get_object(Bucket=source_bucket, Key=source_key)
        content = response["Body"].read().decode("utf-8")
        reader = csv.DictReader(io.StringIO(content))

        password = get_db_password()
        conn = psycopg2.connect(
            host=os.environ["DB_HOST"],
            port=5432,
            dbname="inventoryDB",
            user="postgres",
            password=password,
            connect_timeout=5
        )
        cursor = conn.cursor()

        results = []

        for row in reader:
            order_id = row["order_id"]
            product_id = int(row["product_id"])
            quantity_ordered = int(row["quantity_ordered"])
            customer_name = row["customer_name"]

            cursor.execute(
                "SELECT product_name, unit_price, stock_quantity FROM products WHERE product_id = %s",
                (product_id,)
            )
            product = cursor.fetchone()

            if not product:
                results.append({
                    "order_id": order_id,
                    "product_id": product_id,
                    "customer_name": customer_name,
                    "status": "Product does not exist"
                })
                continue

            product_name, unit_price, stock_quantity = product

            if quantity_ordered <= stock_quantity:
                new_stock = stock_quantity - quantity_ordered
                cursor.execute(
                    "UPDATE products SET stock_quantity = %s WHERE product_id = %s",
                    (new_stock, product_id)
                )
                conn.commit()

                total_price = float(unit_price) * quantity_ordered

                results.append({
                    "order_id": order_id,
                    "product_id": product_id,
                    "product_name": product_name,
                    "customer_name": customer_name,
                    "quantity_ordered": quantity_ordered,
                    "unit_price": float(unit_price),
                    "total_price": total_price,
                    "remaining_stock": new_stock,
                    "status": "Approved"
                })
                print(f"Narudzba {order_id}: Approved, new stock: {new_stock}")
            else:
                results.append({
                    "order_id": order_id,
                    "product_id": product_id,
                    "product_name": product_name,
                    "customer_name": customer_name,
                    "quantity_ordered": quantity_ordered,
                    "available_stock": stock_quantity,
                    "status": "Not enough stock"
                })
                
        cursor.close()
        conn.close()

        output_key = f"processed/processed_{source_key.split('/')[-1].replace('.csv', '.json')}"

        s3.put_object(
            Bucket=os.environ["OUTPUT_BUCKET"],
            Key=output_key,
            Body=json.dumps(results, indent=2, ensure_ascii=False),
            ContentType="application/json"
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Completed", "output_key": output_key, "processed_count": len(results)})
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}