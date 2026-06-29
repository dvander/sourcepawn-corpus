#pragma semicolon 1
#pragma dynamic 645221
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#include <SteamWorks>

public Plugin:myinfo = 
{
	name = "Sample",
	author = "Soroush Falahati",
	description = "Sampling some samples :|",
	version = "0.1",
	url = "http://www.falahati.net/"
}

public OnPluginStart()
{	
	//CreateTimer(10.0, RequestHTTP); // Some delay to be able to see the messages in the console
	RequestHTTP();
}

RequestHTTP()
{
	new Handle:hRequest = SteamWorks_CreateHTTPRequest(EHTTPMethod:k_EHTTPMethodGET, "http://httpbin.org/ip");
	
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	
	SteamWorks_SetHTTPCallbacks(hRequest, HTTP_RequestComplete);

	new data1 = 10;
	new data2 = -60;
	PrintToServer("SAMPLE PLUGIN: Setting %d and %d as HTTP Context Variables", data1, data2);
	SteamWorks_SetHTTPRequestContextValue(hRequest, data1, data2);

	SteamWorks_SendHTTPRequest(hRequest);
}


public HTTP_RequestComplete(Handle:HTTPRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:data1, any:data2)
{	
	PrintToServer("SAMPLE PLUGIN: %d and %d are the active HTTP Context Variables", data1, data2);
	if(bRequestSuccessful)
	{
		CloseHandle(HTTPRequest);
	}
}