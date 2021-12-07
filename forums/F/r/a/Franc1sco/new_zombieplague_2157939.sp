// INCOMPLETED PLUGIN, DONT USE IN A NORMAL SERVER


#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>
#include <zp_beta>

new Handle:array_premios;
new Handle:array_rondas;
new Handle:EnPremioComprado;
new Handle:EnRondaElegida;

new g_creditos[MAXPLAYERS+1];
new bool:special[MAXPLAYERS+1];

enum Rondas
{
	String:Nombre[64],
	probabilidad
}

enum Premios
{
	String:Nombre[64],
	precio,
	quien
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ZP_AddAward", Native_AgregarPremio);
	CreateNative("ZP_AddRound", Native_AgregarRonda);
	CreateNative("ZP_RemoveAward", Native_BorrarPremio);
	CreateNative("ZP_RemoveRound", Native_BorrarRonda);
	CreateNative("ZP_ChooseRound", Native_ElegirRonda);
	CreateNative("ZP_SetSpecial", Native_FijarEspecial);
	CreateNative("ZP_GetSpecial", Native_ObtenerEspecial);
	CreateNative("ZP_SetCredits", Native_FijarCreditos);
	CreateNative("ZP_GetCredits", Native_ObtenerCreditos);
	CreateNative("ZP_LoadTranslations", Native_Lengua);
	EnPremioComprado = CreateGlobalForward("ZP_OnAwardBought", ET_Ignore, Param_Cell, Param_String);
	EnRondaElegida = CreateGlobalForward("ZP_OnRoundSelected", ET_Ignore, Param_String);
    
	return APLRes_Success;
}

public Native_AgregarRonda(Handle:plugin, argc)
{  
	new Items[Rondas];
	GetNativeString(1, Items[Nombre], 64);
	Items[probabilidad] = GetNativeCell(2);
	
	PushArrayArray(array_rondas, Items[0]);
}

public Native_AgregarPremio(Handle:plugin, argc)
{  
	new Items[Premios];
	GetNativeString(1, Items[Nombre], 64);
	Items[precio] = GetNativeCell(2);
	Items[quien] = GetNativeCell(3);
	
	PushArrayArray(array_premios, Items[0]);
}

public Native_BorrarPremio(Handle:plugin, argc)
{  
	decl String:buscado[64];
	GetNativeString(1, buscado, 64);
	
	new Items[Premios];
	for(new i=0;i<GetArraySize(array_premios);++i)
	{
		GetArrayArray(array_premios, i, Items[0]);
		if(StrEqual(Items[Nombre], buscado))
		{
			RemoveFromArray(array_premios, i);
			break;
		}
	}
}

public Native_BorrarRonda(Handle:plugin, argc)
{  
	decl String:buscado[64];
	GetNativeString(1, buscado, 64);
	
	new Items[Rondas];
	for(new i=0;i<GetArraySize(array_rondas);++i)
	{
		GetArrayArray(array_rondas, i, Items[0]);
		if(StrEqual(Items[Nombre], buscado))
		{
			RemoveFromArray(array_rondas, i);
			break;
		}
	}
}

public Native_ElegirRonda(Handle:plugin, argc)
{  
	decl String:buscado[64];
	GetNativeString(1, buscado, 64);
	
	new Items[Rondas];
	for(new i=0;i<GetArraySize(array_rondas);++i)
	{
		GetArrayArray(array_rondas, i, Items[0]);
		if(StrEqual(Items[Nombre], buscado))
		{
			Call_StartForward(EnRondaElegida);
			Call_PushString(Items[Nombre]);
			Call_Finish();
			break;
		}
	}
}

public Native_FijarEspecial(Handle:plugin, argc)
{  
	special[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_ObtenerEspecial(Handle:plugin, argc)
{  
	return special[GetNativeCell(1)];
}

public Native_ObtenerCreditos(Handle:plugin, argc)
{  
	return g_creditos[GetNativeCell(1)];
}

public Native_FijarCreditos(Handle:plugin, argc)
{  
	g_creditos[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_Lengua(Handle:plugin, argc)
{  
	decl String:buscado[64];
	GetNativeString(1, buscado, 64);
	
	LoadTranslations(buscado);
}

public OnPluginStart()
{
	LoadTranslations ("plague.phrases");
	array_premios = CreateArray(66);
	array_rondas = CreateArray(65);
	
	RegConsoleCmd("sm_awards", DOMenu);
	RegConsoleCmd("sm_zp", DOMenu);
	RegAdminCmd("sm_setcredits", FijarCreditos, ADMFLAG_CUSTOM2);
}

public OnPluginEnd()
{
	CloseHandle(array_premios);
	CloseHandle(array_rondas);
}

public Action:DOMenu(client,args)
{
	DID(client);
	PrintToChat(client, "\x04[SM_Franug-ZombiePlague] \x05%t" ,"Tus creditos", g_creditos[client]);
}

public Action:FijarCreditos(client, args)
{
	if(args < 2) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] Utiliza: sm_setcredits <#userid|nombre> [cantidad]");
		return Plugin_Handled;
	}
	decl String:arg2[10];
	//GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	new amount = StringToInt(arg2);
	//new target;
	//decl String:patt[MAX_NAME]
	//if(args == 1) 
	//{ 
	decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget)); 
	// Process the targets 
	decl String:strTargetName[MAX_TARGET_LENGTH]; 
	decl TargetList[MAXPLAYERS], TargetCount; 
	decl bool:TargetTranslate; 
	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToTargetError(client, TargetCount); 
		return Plugin_Handled; 
	} 
	// Apply to all targets 
	for (new i = 0; i < TargetCount; i++) 
	{ 
		new iClient = TargetList[i]; 
		if (IsClientInGame(iClient)) 
		{ 
			g_creditos[iClient] = amount;
			PrintToChat(client, "\x04[SM_Franug-ZombiePlague] \x05Puesto %i creditos en el jugador %N", amount, iClient);
		} 
	} 
	//}  
	//    SetEntProp(target, Prop_Data, "m_iDeaths", amount);
	return Plugin_Continue;
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "ZombiePlague by Franug");
	decl String:MenuItem[128];
	decl String:tnombre[32];
	decl String:tparaquien[32];
	decl String:creditos[32];
	
	new Handle:array_premios_clon = CloneArray(array_premios);
	
	while(GetArraySize(array_premios_clon)>0)
	{
		new menor;
		new Items[GetArraySize(array_premios_clon)][Premios];
		for(new i2=0;i2<GetArraySize(array_premios_clon);++i2)
		{
			GetArrayArray(array_premios_clon, i2, Items[i2][0]);
			
			if(Items[i2][precio] <= Items[menor][precio])
			{
				menor = i2;
			}
		}

		Format(tnombre, sizeof(tnombre),"%T", Items[menor][Nombre], clientId);
		switch(Items[menor][quien])
		{
			case ZP_HUMANS:Format(tparaquien, 32, "%T", "Humanos", clientId);
			case ZP_ZOMBIES:Format(tparaquien, 32, "%T", "Zombies", clientId);
			case ZP_BOTH:Format(tparaquien, 32, "%T", "Ambos", clientId);
		}
		Format(creditos, sizeof(creditos),"%T", "Creditos", clientId);
		
		Format(MenuItem, sizeof(MenuItem),"%s (%s) - %i %s",tnombre, tparaquien, Items[menor][precio], creditos);
		AddMenuItem(menu, Items[menor][Nombre], MenuItem);
		
		RemoveFromArray(array_premios_clon, menor);
		
	}
	CloseHandle(array_premios_clon);
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		decl String:info[64];
		new Items[Premios];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		for(new i=0;i<GetArraySize(array_premios);++i)
		{
			GetArrayArray(array_premios, i, Items[0]);
			if(StrEqual(Items[Nombre], info))
			{
				break;
			}
		}
		
		
		if (g_creditos[client] >= Items[precio])
		{
			if (IsPlayerAlive(client))
			{
				if (Items[quien] == ZP_BOTH || (ZR_IsClientZombie(client) && Items[quien] == ZP_ZOMBIES) || (ZR_IsClientHuman(client) && Items[quien] == ZP_HUMANS))
				{
					if(special[client])
					{
						PrintToChat(client,"\x04[SM_Franug-ZombiePlague] \x05%t","No puedes comprar cosas siendo un ser especial");
						return;
					}
					g_creditos[client] -= Items[precio];
						
					Call_StartForward(EnPremioComprado);
					Call_PushCell(client);
					Call_PushString(info);
					Call_Finish();
				}
				else
				{
					PrintToChat(client, "\x04[SM_Franug-ZombiePlague] \x05%t","Este premio no esta disponible para tu equipo");
				}
			}
			else
			{
				PrintToChat(client, "\x04[SM_Franug-ZombiePlague] \x05%t","Tienes que estar vivo para poder comprar premios");
			}
		}
		else
		{
			PrintToChat(client, "\x04[SM_Franug-ZombiePlague] \x05%t","Necesitas creditos", g_creditos[client],Items[precio]);
		}
		DID(client);
		
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public OnClientPostAdminCheck(client)
{
	g_creditos[client] = 0;
	special[client] = false;
}
