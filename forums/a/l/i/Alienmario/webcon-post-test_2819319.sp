#include <sourcemod>
#include <webcon>

#pragma semicolon 1
#pragma newdecls required

#define INDEX_HTML "\
<!doctype html>\
<html lang='en'>\
	\
	<head>\
		<meta charset='utf-8'>\
	</head>\
	\
	<body>\
		<h1>Form with enctype = application/x-www-form-urlencoded</h1>\
		<form action='' method='POST' enctype='application/x-www-form-urlencoded'>\
		<input type='text' id='param' name='param'>\
		<input type='submit' value='Submit'>\
		</form>\
		\
		<h1>Form with enctype = multipart/form-data</h1>\
		<form action='' method='POST' enctype='multipart/form-data'>\
		<input type='text' id='param' name='param'>\
		<input type='submit' value='Submit'>\
		</form>\
		\
		<h1>Form with enctype = text/plain</h1>\
		<form action='' method='POST' enctype='text/plain'>\
		<input type='text' id='param' name='param'>\
		<input type='submit' value='Submit'>\
		</form>\
	</body>\
</html>\
"

WebResponse rspIndex;

public void OnPluginStart()
{
	if (!Web_RegisterRequestHandler("test", OnWebRequest, "test"))
	{
		SetFailState("Failed to register request handler.");
	}
	rspIndex = new WebStringResponse(INDEX_HTML);
	rspIndex.AddHeader(WebHeader_ContentType, "text/html; charset=UTF-8");
}

public bool OnWebRequest(WebConnection connection, const char[] method, const char[] url)
{
	char buffer[128];
	bool gotParam = connection.GetRequestData(WebRequestDataType_Post, "param", buffer, sizeof(buffer));
	PrintToServer("gotParam = %d; param = \"%s\"", gotParam, buffer);

	return connection.QueueResponse(WebStatus_OK, rspIndex);
}