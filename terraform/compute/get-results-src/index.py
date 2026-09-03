import json
import os
import boto3

s3 = boto3.client("s3")

def handler(event, context):
    try:
        bucket = os.environ["RESULTS_BUCKET"]
        prefix  = "processed/"

        params = event.get("queryStringParameters") or {}
        limit   = int(params.get("limit", 1))

        response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)

        if "Contents" not in response:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "No data", "results": []})
            }

        sorted_files = sorted(response["Contents"], key=lambda x: x["LastModified"], reverse=True)
        selected_files = sorted_files[:limit]

        results = []

        for file_obj in selected_files:
            obj = s3.get_object(Bucket=bucket, Key=file_obj["Key"])
            content = json.loads(obj["Body"].read().decode("utf-8"))

            results.append({
                "file": file_obj["Key"],
                "last_modified": file_obj["LastModified"].isoformat(),
                "data": content
            })

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "requested_limit": limit,
                "returned_count": len(results),
                "results": results
            }, ensure_ascii=False)
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }