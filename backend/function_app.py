import logging
import azure.functions as func
from azure.data.tables import TableServiceClient
import os
import json

app = func.FunctionApp()

@app.route(route="GetVisitorCount", auth_level=func.AuthLevel.ANONYMOUS)
def GetVisitorCount(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Visitor counter function triggered.')

    try:
        connection_string = os.environ["COSMOS_CONNECTION_STRING"]
        table_service = TableServiceClient.from_connection_string(connection_string)
        table_client = table_service.get_table_client(table_name="VisitorCount")

        entity = table_client.get_entity(partition_key="counter", row_key="1")
        entity["count"] += 1
        table_client.update_entity(entity)

        response_body = json.dumps({"count": entity["count"]})

        return func.HttpResponse(
            response_body,
            status_code=200,
            mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "*"}
        )

    except Exception as e:
        logging.error(f"Error updating visitor count: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )