#include <sourcemod>

public Plugin:myinfo = 
{
	name = "center scroll",
	author = "samu",
	description = "",
	version = "1.0",
	url = ""
}
 
new  String:g_message[128];
new  String:wshow[32];
new  gxpos;
new  gxmax;
new  gxframe;
new  gxsetoff;
new  g_repeat = -16;
#define schidSHOW 0.3

// cvars
new Handle:convar_message = INVALID_HANDLE;

// defines
#define FREQ 50.0

public OnPluginStart()
{
	convar_message = CreateConVar("center_scrollmsg","this is a test message");
	
	CreateTimer(FREQ,fn_DisplayMsg,_,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:fn_DisplayMsg(Handle:timer)
{
	PrintToChatAll("am deschis fn_DisplayMsg");
	
	gxmax = gxpos = GetConVarString(convar_message,g_message,sizeof(g_message));

	if (gxmax)  
	{
		gxframe = 32;
		gxsetoff = 0;
		//SetChar( wshow, 31 , ' ' );
		wshow[31] = ' ';

		g_repeat = -16;
		CreateTimer(schidSHOW,fn_ShowScrollMsg,_,TIMER_REPEAT);
		
		PrintToChatAll("am creat timer pt fn_ShowScrollMsg si gxpos era : %d",gxpos);
	}
}


public Action:fn_ShowScrollMsg(Handle:timer)
{
	//if(g_repeat >= gxpos + 31 - 15)
	//{
		//PrintToChatAll("g_repeat >= gxpos +1 cu valoarea : %d",gxpos);
		//g_repeat = -16;
		//return Plugin_Stop;
	//}
	
	if (gxframe)
		--gxframe;
	else
		++gxsetoff;

	new a = strcopy( wshow[ gxframe ] , gxmax - gxsetoff - gxpos-- , g_message[ gxsetoff ] ) + gxframe;
  
	if ( a < 31 ) wshow[ a ] = ' ';
	
	PrintCenterTextAll(wshow);
	
	//g_repeat++;	
	
	return Plugin_Continue;
}


stock SetChar(String:str[],len,char)
{
	if(strlen(str) < len)
		return;
	
	str[len] = char;
}