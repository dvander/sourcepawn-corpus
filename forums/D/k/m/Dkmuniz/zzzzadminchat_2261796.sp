#include <sourcemod>
#include <csgocolors>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
 
new Handle:g_h_CVAR_Tag = INVALID_HANDLE;
new Handle:g_h_CVAR_Tagd = INVALID_HANDLE;
new Handle:g_h_CVAR_Tagm = INVALID_HANDLE;
new Handle:g_h_CVAR_Tagv = INVALID_HANDLE;
 
new Handle:g_h_CVAR_CTag = INVALID_HANDLE;
new Handle:g_h_CVAR_CName = INVALID_HANDLE;
new Handle:g_h_CVAR_CText = INVALID_HANDLE;
 
new Handle:g_h_CVAR_CTagd = INVALID_HANDLE;
new Handle:g_h_CVAR_CNamed = INVALID_HANDLE;
new Handle:g_h_CVAR_CTextd = INVALID_HANDLE;
 
new Handle:g_h_CVAR_CTagm = INVALID_HANDLE;
new Handle:g_h_CVAR_CNamem = INVALID_HANDLE;
new Handle:g_h_CVAR_CTextm = INVALID_HANDLE;
 
new Handle:g_h_CVAR_CTagv = INVALID_HANDLE;
new Handle:g_h_CVAR_CNamev = INVALID_HANDLE;
new Handle:g_h_CVAR_CTextv = INVALID_HANDLE;

 
 
public Plugin:myinfo =
{
        name = "Cor no chat",
        author = "Dk --",
        description = "Cor no chat para admins/donos/master",
        version = "private",
}
 
 
public OnPluginStart()
{

	g_h_CVAR_Tag = CreateConVar("sm_tag", "[ADMIN] ", "Tag para o admin normal");
	g_h_CVAR_Tagd = CreateConVar("sm_tagdono", "[DONO] ", "Tag para o dono");
	g_h_CVAR_Tagm = CreateConVar("sm_tagmaster", "[ADMIN MASTER] ", "Tag para o admin master");
	g_h_CVAR_Tagv = CreateConVar("sm_tagmastev", "[VETERANO] ", "Tag para o admin veterano");
   
	g_h_CVAR_CTag = CreateConVar("sm_color_tag", "GREEN", "Cor da tag para o admin normal");
	g_h_CVAR_CName = CreateConVar("sm_color_name", "BLUE", "Cor do nome do admin normal");
	g_h_CVAR_CText = CreateConVar("sm_color_text", "LIGHTGREEN", "Cor do texto do admin normal");
   
	g_h_CVAR_CTagd = CreateConVar("sm_color_tagd", "GREEN", "Cor da tag para o dono");
	g_h_CVAR_CNamed = CreateConVar("sm_color_named", "BLUE", "Cor do nome para o dono");
	g_h_CVAR_CTextd = CreateConVar("sm_color_textd", "PURPLE", "Cor do texto do dono");
   
	g_h_CVAR_CTagm = CreateConVar("sm_color_tagm", "GREEN", "Cor da tag para o admin master");
	g_h_CVAR_CNamem = CreateConVar("sm_color_namem", "BLUE", "Cor do nome para o admin master");
	g_h_CVAR_CTextm = CreateConVar("sm_color_textm", "RED", "Cor do texto do admin master");
   
	g_h_CVAR_CTagv = CreateConVar("sm_color_tagv", "BLUE", "Cor da tag para o admin master");
	g_h_CVAR_CNamev = CreateConVar("sm_color_namev", "GREEN", "Cor do nome para o admin master");
	g_h_CVAR_CTextv = CreateConVar("sm_color_textv", "RED", "Cor do texto do admin master");
   
	AutoExecConfig(true, "AdminChat");
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say2, "say_team");
}
 
 
public Action:Command_Say(client, const String:command[], args)
{
	decl String:sText[192];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if(!sText[0])
	{
		return Plugin_Handled;
	}
	
	if(sText[0] == '/')
	{
		return Plugin_Continue;
	}
   
	new AdminId:ID = GetUserAdmin(client);
   
	/* Check if the client is an admin */
	if(ID != INVALID_ADMIN_ID)
	{
			/* Check if the client is valid */
			if(IsClientInGame(client))
			{
				AdminChat(client, sText);
			}
	}
   
	else
	{
		return Plugin_Continue;
	}
   
	return Plugin_Handled;
}

public Action:Command_Say2(client, const String:command[], args)
{
	decl String:sText2[192];
	GetCmdArgString(sText2, sizeof(sText2));
	StripQuotes(sText2);
	
	if(!sText2[0])
	{
			//Return:
			return Plugin_Handled;
	}
   
	new AdminId:ID = GetUserAdmin(client);
   
	/* Check if the client is an admin */
	if(ID != INVALID_ADMIN_ID)
	{
			/* Check if the client is valid */
			if(IsClientInGame(client))
			{
				AdminChat2(client, sText2);
			}
	}
   
	else
	{
		return Plugin_Continue;
	}
   
	return Plugin_Handled;
}
 
 
AdminChat(client, String:sText[192])
{
	if(CheckCommandAccess(client, "", ADMFLAG_ROOT  ) )
	{
		new String:sTagd[20];
		GetConVarString(g_h_CVAR_Tagd, sTagd, sizeof(sTagd));
	   
		new String:Color_Tagd[20];
		GetConVarString(g_h_CVAR_CTagd, Color_Tagd, sizeof(Color_Tagd));

		new String:Color_Named[20];
		GetConVarString(g_h_CVAR_CNamed, Color_Named, sizeof(Color_Named));
	   
		new String:Color_Textd[20];
		GetConVarString(g_h_CVAR_CTextd, Color_Textd, sizeof(Color_Textd));
	   
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{  
				if(IsPlayerAlive(i))
				{
					CPrintToChat(i,"{%s}%s{%s}%N: {%s}%s", Color_Tagd, sTagd, Color_Named, client, Color_Textd, sText);
				}
				else
				{
					CPrintToChat(i,"*DEAD* {%s}%s{%s}%N: {%s}%s", Color_Tagd, sTagd, Color_Named, client, Color_Textd, sText);
				}
			}
		}
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_GENERIC  ) && !CheckCommandAccess(client, "", ADMFLAG_CUSTOM1  ) )
	{
		new String:sTag[20];
		GetConVarString(g_h_CVAR_Tag, sTag, sizeof(sTag));
	   
		new String:Color_Tag[20];
		GetConVarString(g_h_CVAR_CTag, Color_Tag, sizeof(Color_Tag));
	   
		new String:Color_Name[20];
		GetConVarString(g_h_CVAR_CName, Color_Name, sizeof(Color_Name));
	   
		new String:Color_Text[20];
		GetConVarString(g_h_CVAR_CText, Color_Text, sizeof(Color_Text));
	   
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					CPrintToChat(i,"{%s}%s{%s}%N: {%s}%s", Color_Tag, sTag, Color_Name, client, Color_Text, sText);
				}
				else
				{
					CPrintToChat(i,"*DEAD* {%s}%s{%s}%N: {%s}%s", Color_Tag, sTag, Color_Name, client, Color_Text, sText);
				}
			}			
		}    
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_CUSTOM1  ) && CheckCommandAccess(client, "", ADMFLAG_CUSTOM2 ) )
	{
		new String:sTagm[20];
		GetConVarString(g_h_CVAR_Tagm, sTagm, sizeof(sTagm));
	   
		new String:Color_Tagm[20];
		GetConVarString(g_h_CVAR_CTagm, Color_Tagm, sizeof(Color_Tagm));
	   
		new String:Color_Namem[20];
		GetConVarString(g_h_CVAR_CNamem, Color_Namem, sizeof(Color_Namem));
	   
		new String:Color_Textm[20];
		GetConVarString(g_h_CVAR_CTextm, Color_Textm, sizeof(Color_Textm));
	   
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					CPrintToChat(i,"{%s}%s{%s}%N: {%s}%s", Color_Tagm, sTagm, Color_Namem, client, Color_Textm, sText);
				}
				else
				{
					CPrintToChat(i,"*DEAD* {%s}%s{%s}%N: {%s}%s", Color_Tagm, sTagm, Color_Namem, client, Color_Textm, sText);
				}
			}
		}  
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_CUSTOM3  ) && CheckCommandAccess(client, "", ADMFLAG_CUSTOM4 ) )
	{
		new String:sTagv[20];
		GetConVarString(g_h_CVAR_Tagv, sTagv, sizeof(sTagv));
	   
		new String:Color_Tagv[20];
		GetConVarString(g_h_CVAR_CTagv, Color_Tagv, sizeof(Color_Tagv));

		new String:Color_Namev[20];
		GetConVarString(g_h_CVAR_CNamev, Color_Namev, sizeof(Color_Namev));
	   
		new String:Color_Textv[20];
		GetConVarString(g_h_CVAR_CTextv, Color_Textv, sizeof(Color_Textv));
	   
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					CPrintToChat(i,"{%s}%s{%s}%N: {%s}%s", Color_Tagv, sTagv, Color_Namev, client, Color_Textv, sText);
				}
				else
				{
					CPrintToChat(i,"*DEAD* {%s}%s{%s}%N: {%s}%s", Color_Tagv, sTagv, Color_Namev, client, Color_Textv, sText);
				}
			}
		}  
	}
}
 
AdminChat2(client, String:sText2[192])
{
	if(CheckCommandAccess(client, "", ADMFLAG_ROOT  ) )
	{
		new String:sTagd2[20];
		GetConVarString(g_h_CVAR_Tagd, sTagd2, sizeof(sTagd2));
	   
		new String:Color_Tagd2[20];
		GetConVarString(g_h_CVAR_CTagd, Color_Tagd2, sizeof(Color_Tagd2));

		new String:Color_Named2[20];
		GetConVarString(g_h_CVAR_CNamed, Color_Named2, sizeof(Color_Named2));
	   
		new String:Color_Textd2[20];
		GetConVarString(g_h_CVAR_CTextd, Color_Textd2, sizeof(Color_Textd2));
	   
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagd2, sTagd2, Color_Named2, client, Color_Textd2, sText2);   
					}
					else
					{
						CPrintToChat(i,"(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagd2, sTagd2, Color_Named2, client, Color_Textd2, sText2);   
					}
				}
				else
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"*DEAD*(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagd2, sTagd2, Color_Named2, client, Color_Textd2, sText2);  
					}
					else
					{
						CPrintToChat(i,"*DEAD*(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagd2, sTagd2, Color_Named2, client, Color_Textd2, sText2);   	
					}
				}
			}
		}		
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_GENERIC  ) && !CheckCommandAccess(client, "", ADMFLAG_CUSTOM1  ) )
	{
		new String:sTag2[20];
		GetConVarString(g_h_CVAR_Tag, sTag2, sizeof(sTag2));
	   
		new String:Color_Tag2[20];
		GetConVarString(g_h_CVAR_CTag, Color_Tag2, sizeof(Color_Tag2));
	   
		new String:Color_Name2[20];
		GetConVarString(g_h_CVAR_CName, Color_Name2, sizeof(Color_Name2));
	   
		new String:Color_Text2[20];
		GetConVarString(g_h_CVAR_CText, Color_Text2, sizeof(Color_Text2));
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tag2, sTag2, Color_Name2, client, Color_Text2, sText2);   
					}
					else
					{
						CPrintToChat(i,"(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tag2, sTag2, Color_Name2, client, Color_Text2, sText2);   
					}
				}
				else
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"*DEAD*(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tag2, sTag2, Color_Name2, client, Color_Text2, sText2);  
					}
					else
					{
						CPrintToChat(i,"*DEAD*(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tag2, sTag2, Color_Name2, client, Color_Text2, sText2);   	
					}
				}
			}
		}		
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_CUSTOM1  ) && CheckCommandAccess(client, "", ADMFLAG_CUSTOM2 ) )
	{
		new String:sTagm2[20];
		GetConVarString(g_h_CVAR_Tagm, sTagm2, sizeof(sTagm2));
	   
		new String:Color_Tagm2[20];
		GetConVarString(g_h_CVAR_CTagm, Color_Tagm2, sizeof(Color_Tagm2));

		new String:Color_Namem2[20];
		GetConVarString(g_h_CVAR_CNamem, Color_Namem2, sizeof(Color_Namem2));
	   
		new String:Color_Textm2[20];
		GetConVarString(g_h_CVAR_CTextm, Color_Textm2, sizeof(Color_Textm2));
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagm2, sTagm2, Color_Namem2, client, Color_Textm2, sText2);   
					}
					else
					{
						CPrintToChat(i,"(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagm2, sTagm2, Color_Namem2, client, Color_Textm2, sText2);   
					}
				}
				else
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"*DEAD*(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagm2, sTagm2, Color_Namem2, client, Color_Textm2, sText2);  
					}
					else
					{
						CPrintToChat(i,"*DEAD*(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagm2, sTagm2, Color_Namem2, client, Color_Textm2, sText2);   	
					}
				}
			}
		}		
	}
	else if(CheckCommandAccess(client, "", ADMFLAG_CUSTOM3  ) && CheckCommandAccess(client, "", ADMFLAG_CUSTOM4 ) )
	{
		new String:sTagv2[20];
		GetConVarString(g_h_CVAR_Tagv, sTagv2, sizeof(sTagv2));
	   
		new String:Color_Tagv2[20];
		GetConVarString(g_h_CVAR_CTagv, Color_Tagv2, sizeof(Color_Tagv2));

		new String:Color_Namev2[20];
		GetConVarString(g_h_CVAR_CNamev, Color_Namev2, sizeof(Color_Namev2));
	   
		new String:Color_Textv2[20];
		GetConVarString(g_h_CVAR_CTextv, Color_Textv2, sizeof(Color_Textv2));
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{ 
				if(IsPlayerAlive(i))
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagv2, sTagv2, Color_Namev2, client, Color_Textv2, sText2);   
					}
					else
					{
						CPrintToChat(i,"(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagv2, sTagv2, Color_Namev2, client, Color_Textv2, sText2);   
					}
				}
				else
				{
					if(GetClientTeam(i) == 3)
					{
						CPrintToChat(i,"*DEAD*(Guardas) {%s}%s{%s}%N: {%s}%s", Color_Tagv2, sTagv2, Color_Namev2, client, Color_Textv2, sText2);  
					}
					else
					{
						CPrintToChat(i,"*DEAD*(Prisioneiros) {%s}%s{%s}%N: {%s}%s", Color_Tagv2, sTagv2, Color_Namev2, client, Color_Textv2, sText2);   	
					}
				}
			}
		}	
	}
}
 
 