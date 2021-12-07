#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("sm_prop", CmdProp, "prop");
	RegConsoleCmd("sm_setprop", CmdSetProp, "setprop");
}

public Action:CmdProp(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "Specify the property type and property name dude. [float | int | string | bool | vec] [send | data] [name]");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256], String:arg3[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	if(StrEqual(arg1, "int") || StrEqual(arg1, "bool"))
	{
		new i;
		if(StrEqual(arg2, "send"))
		{
			i = GetEntProp(client, Prop_Send, arg3);
		}
		else if(StrEqual(arg2, "data"))
		{
			i = GetEntProp(client, Prop_Data, arg3);
		}
		PrintToChat(client, "Property '%s': %i", arg3, i);
	}
	else if(StrEqual(arg1, "float"))
	{
		decl Float:i;
		if(StrEqual(arg2, "send"))
		{
			i = GetEntPropFloat(client, Prop_Send, arg3);
		}
		else if(StrEqual(arg2, "data"))
		{
			i = GetEntPropFloat(client, Prop_Data, arg3);
		}
		PrintToChat(client, "Property '%s': %f", arg3, i);
	}
	else if(StrEqual(arg1, "string"))
	{
		decl String:i[256];
		if(StrEqual(arg2, "send"))
		{
			GetEntPropString(client, Prop_Send, arg3, i, sizeof(i));
		}
		else if(StrEqual(arg2, "data"))
		{
			GetEntPropString(client, Prop_Data, arg3, i, sizeof(i));
		}
		PrintToChat(client, "Property '%s': %s", arg3, i);
	}
	else
	{
		PrintToChat(client, "Invalid type");
	}
	return Plugin_Handled;
}

public Action:CmdSetProp(client, args)
{
	if(args < 2)
	{
		PrintToChat(client, "Specify the property type and property name dude. [float | int | string | bool | vec] [send | data] [name] [value]");
		return Plugin_Handled;
	}
	decl String:arg1[256], String:arg2[256], String:arg3[256], String:arg4[256];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	if(StrEqual(arg1, "int") || StrEqual(arg1, "bool"))
	{
		new i;
		if(StrEqual(arg2, "send"))
		{
			i = StringToInt(arg4);
			SetEntProp(client, Prop_Send, arg3, i);
		}
		else if(StrEqual(arg2, "data"))
		{
			i = StringToInt(arg4);
			SetEntProp(client, Prop_Data, arg3, i);
		}
		PrintToChat(client, "Property '%s': %i", arg3, i);
	}
	else if(StrEqual(arg1, "float"))
	{
		decl Float:i;
		if(StrEqual(arg2, "send"))
		{
			i = StringToFloat(arg4);
			SetEntPropFloat(client, Prop_Send, arg3, i);
		}
		else if(StrEqual(arg2, "data"))
		{
			i = StringToFloat(arg4);
			SetEntPropFloat(client, Prop_Data, arg3, i);
		}
	}
	else if(StrEqual(arg1, "string"))
	{
		if(StrEqual(arg2, "send"))
		{
			SetEntPropString(client, Prop_Send, arg3, arg4);
		}
		else if(StrEqual(arg2, "data"))
		{
			SetEntPropString(client, Prop_Data, arg3, arg4);
		}
	}
	else
	{
		PrintToChat(client, "Invalid type");
	}
	return Plugin_Handled;
}