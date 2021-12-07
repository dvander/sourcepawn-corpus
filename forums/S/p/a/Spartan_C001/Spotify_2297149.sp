#include <sourcemod>
#include <steamtools>
#include <smjansson>
#include <regex>

#define PLUGIN_VERSION  "1.0.2"

public Plugin:myinfo={name="[ANY] Spotify:Source",author="Spartan C001",description="Play songs from Spotify.",version=PLUGIN_VERSION,url="https://forums.alliedmods.net/showthread.php?t=226704"}

new bool:IsClientNotified[MAXPLAYERS+1]={false,...}

public OnPluginStart()
{
	CreateConVar("spotify_source_version",PLUGIN_VERSION,"Spotify:Source Version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("sm_sp",CMD_PLAY,"Play a song.")
	RegConsoleCmd("sm_spstop",CMD_STOP,"Stop any music.")
	RegConsoleCmd("sm_sp_reset",CMD_RESET,"Reset client variable.")
}

public OnClientConnected(client)
{
	IsClientNotified[client]=false
}

public Action:CMD_RESET(client,args)
{
	if(client)
	{
		PrintToChat(client,"\x07FF8C00[Spotify] \x01Success,your next song will bring up the web page.")
		IsClientNotified[client]=false
	}
	return Plugin_Handled
}

public Action:CMD_STOP(client,args)
{
	if(client)
	{
		new Handle:setup=CreateKeyValues("data")
		KvSetString(setup,"title","Spotify")
		KvSetNum(setup,"type",MOTDPANEL_TYPE_URL)
		KvSetString(setup,"msg","about:blank")
		ShowVGUIPanel(client,"info",setup,false)
		CloseHandle(setup)
		PrintToChat(client,"\x07FF8C00[Spotify] \x01Music Stopped.")
	}
	return Plugin_Handled
}

public Action:CMD_PLAY(client,args)
{
	if(client && args)
	{
		new String:search[256]
		GetCmdArgString(search,256)
		ReplaceString(search,256," ","+")
		ReplaceString(search,256,".","+")
		if(SimpleRegexMatch(search,"([^A-Za-z0-9+'])")>0)
		{
			PrintToChat(client,"\x07FF8C00[Spotify] \x01Error: Search contains invalid characters.")
			return Plugin_Handled
		}
		new HTTPRequestHandle:request = Steam_CreateHTTPRequest(HTTPMethod_GET,"https://api.spotify.com/v1/search")
		Steam_SetHTTPRequestGetOrPostParameter(request,"q",search)
		Steam_SetHTTPRequestGetOrPostParameter(request,"limit","1")
		Steam_SetHTTPRequestGetOrPostParameter(request,"type","track")
		Steam_SetHTTPRequestHeaderValue(request,"Pragma","no-cache")
		Steam_SetHTTPRequestHeaderValue(request,"Cache-Control","no-cache")
		Steam_SendHTTPRequest(request,SongQueryComplete,client)
	}
	return Plugin_Handled
}

public SongQueryComplete(HTTPRequestHandle:request,bool:successful,HTTPStatusCode:status,any:client)
{
	if(successful && status == HTTPStatusCode_OK)
	{
		new String:response[8192]
		Steam_GetHTTPResponseBodyData(request,response,8192)
		Steam_ReleaseHTTPRequest(request)
		new Handle:ResponseKV=CreateKeyValues("root")
		new Handle:ResponseObject = json_load(response)
		ProcessElement("root",ResponseObject,ResponseKV)
		CloseHandle(ResponseObject)
		new String:Result[3][256]
		KvRewind(ResponseKV)
		KvJumpToKey(ResponseKV,"root")
		KvJumpToKey(ResponseKV,"root")
		KvJumpToKey(ResponseKV,"tracks")
		KvJumpToKey(ResponseKV,"items")
		KvJumpToKey(ResponseKV,"0")
		KvGetString(ResponseKV,"name",Result[0],256)
		KvJumpToKey(ResponseKV,"artists")
		KvJumpToKey(ResponseKV,"0")
		KvGetString(ResponseKV,"name",Result[1],256)
		KvGoBack(ResponseKV)
		KvGoBack(ResponseKV)
		KvJumpToKey(ResponseKV,"external_urls")
		KvGetString(ResponseKV,"spotify",Result[2],256)
		CloseHandle(ResponseKV)
		if(strlen(Result[2])==0)
		{
			PrintToChat(client,"\x07FF8C00[Spotify] \x01No song found.")
		}
		else
		{
			PrintToChatAll("\x07FF8C00[Spotify] \x01Player \x073EFF3E%N \x01is now listening to \x073EFF3E%s \x01by \x073EFF3E%s\x01.",client,Result[0],Result[1])
			if(!IsClientNotified[client])
			{
				ShowMOTDPanel(client,"Spotify",Result[2],MOTDPANEL_TYPE_URL)
				IsClientNotified[client]=true
			}
			else
			{
				new Handle:setup = CreateKeyValues("data")
				KvSetString(setup,"title","Spotify")
				KvSetNum(setup,"type",MOTDPANEL_TYPE_URL)
				KvSetString(setup,"msg",Result[2])
				ShowVGUIPanel(client,"info",setup,false)
				CloseHandle(setup)
			}
		}
	}
	else
	{
		PrintToChat(client,"\x07FF8C00[Spotify] \x01Error: Could not contact API server.")
	}
}

public ProcessElement(String:sKey[],Handle:hObj,Handle:g_hKV)
{
	switch(json_typeof(hObj))
	{
		case JSON_OBJECT:
		{
			KvJumpToKey(g_hKV,sKey,true)
			IterateJsonObject(Handle:hObj,g_hKV)
			KvGoBack(g_hKV)
		}
		case JSON_ARRAY:
		{
			KvJumpToKey(g_hKV,sKey,true)
			IterateJsonArray(Handle:hObj,g_hKV)
			KvGoBack(g_hKV)
		}
		case JSON_STRING:
		{
			new String:sString[1024]
			json_string_value(hObj,sString,sizeof(sString))
			KvSetString(g_hKV,sKey,sString)
		}
		case JSON_INTEGER:
		{
			KvSetNum(g_hKV,sKey,json_integer_value(hObj))
		}
		case JSON_REAL:
		{
			KvSetFloat(g_hKV,sKey,json_real_value(hObj))
		}
		case JSON_TRUE:
		{
			KvSetNum(g_hKV,sKey,1)
		}
		case JSON_FALSE:
		{
			KvSetNum(g_hKV,sKey,0)
		}
		case JSON_NULL:
		{
			KvSetString(g_hKV,sKey,"")
		}
	}
}

public IterateJsonArray(Handle:hArray,Handle:g_hKV)
{
	for(new iElement = 0; iElement < json_array_size(hArray); iElement++)
	{
		new Handle:hValue = json_array_get(hArray,iElement)
		new String:sElement[4]
		IntToString(iElement,sElement,sizeof(sElement))
		ProcessElement(sElement,hValue,g_hKV)
		CloseHandle(hValue)
	}
}

public IterateJsonObject(Handle:hObj,Handle:g_hKV)
{
	new Handle:hIterator = json_object_iter(hObj)
	while(hIterator != INVALID_HANDLE)
	{
		new String:sKey[128]
		json_object_iter_key(hIterator,sKey,sizeof(sKey))
		new Handle:hValue = json_object_iter_value(hIterator)
		ProcessElement(sKey,hValue,g_hKV)
		CloseHandle(hValue)
		hIterator=json_object_iter_next(hObj,hIterator)
	}
}  