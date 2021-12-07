#pragma semicolon 1

/* Includes */
#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <ctx>

/* Defines */
#define PLUGIN_VERSION			"1.0"
#define PLUGIN_DESCRIPTION		"A fun on the fly method of dealing with CTX Values."

/* Plugin Information */
public Plugin:myinfo =
{
    name 		=		"CTX Tools",			// http://www.youtube.com/watch?v=3LI5imnhvro&hd=1
    author		=		"Kyle Sanderson",
    description	=		 PLUGIN_DESCRIPTION,
    version		=		 PLUGIN_VERSION,
    url			=		"http://SourceMod.net"
};

public OnPluginStart()
{
	RegAdminCmd("sm_ctx_get", OnCTXGet, ADMFLAG_ROOT, "Gets whatever value you input.");
	RegAdminCmd("sm_ctx_set", OnCTXSet, ADMFLAG_ROOT, "Sets whatever value you input.");
	RegAdminCmd("sm_ctx_resetclass", OnCTXResetClass, ADMFLAG_ROOT, "Resets a classes CTX value to it's original value.");
	RegAdminCmd("sm_ctx_resettype", OnCTXResetType, ADMFLAG_ROOT, "Resets every specified type changed CTX value to it's original value.");
}

public Action:OnCTXGet(client, args)
{
	if(args != 4)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 sm_ctx_get CTXType CTXDataType CTXVariableName CTXClassName");
		return Plugin_Handled;
	}
	
	decl String:sArg[64];
	
	if(GetCmdArg(1, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXType;
	
	switch(sArg[4])
	{
		case 'P','p':
		{
			if(sArg[10] == '\0')
			{
				CTXType = CTX_PLAYER;
			}
			else
			{
				CTXType = CTX_PLAYER_TEAM2;
			}
		}
		
		case 'W','w':
		{
			CTXType = CTX_WEAPON;
		}
		
		case 'O','o':
		{
			CTXType = CTX_OBJECT;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	if(GetCmdArg(2, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXDataType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXDataType;
	
	switch(sArg[4])
	{
		case 'S','s':
		{
			CTXDataType = CTX_STRING;
		}
		
		case 'B','b':
		{
			CTXDataType = CTX_BOOL;
		}
		
		case 'I','i':
		{
			CTXDataType = CTX_INT;
		}
		
		case 'F','f':
		{
			CTXDataType = CTX_FLOAT;
		}
		
		case 'P','p':
		{
			CTXDataType = CTX_PTR_STRING;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXDataType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	decl String:sVariable[64], String:sClassName[64], String:sReturnedValue[64];
	GetCmdArg(3, sVariable, sizeof(sVariable));
	GetCmdArg(4, sClassName, sizeof(sClassName));
	
	sReturnedValue[0] = '\0';
	switch(CTX_Get(CTXType, CTXDataType, sVariable, sClassName, sReturnedValue))
	{
		case 0:
		{
			decl String:sArgString[512];
			GetCmdArgString(sArgString, sizeof(sArgString));
			ReplyToCommand(client, "\x04[CTX]\x03 Query Failed with: \x04%s\x03.", sArgString);
		}
		
		case 1:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 The Value of \x04%s\x03 is \x04%s\x03.", sVariable, sReturnedValue);
		}
	}
	return Plugin_Handled;
}

public Action:OnCTXSet(client, args)
{
	if(args != 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 sm_ctx_set CTXType CTXDataType CTXVariableName CTXClassName PreposedValue");
		return Plugin_Handled;
	}
	
	decl String:sArg[64];
	
	if(GetCmdArg(1, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXType;
	
	switch(sArg[4])
	{
		case 'P','p':
		{
			if(sArg[10] == '\0')
			{
				CTXType = CTX_PLAYER;
			}
			else
			{
				CTXType = CTX_PLAYER_TEAM2;
			}
		}
		
		case 'W','w':
		{
			CTXType = CTX_WEAPON;
		}
		
		case 'O','o':
		{
			CTXType = CTX_OBJECT;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	if(GetCmdArg(2, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXDataType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXDataType;
	
	switch(sArg[4])
	{
		case 'S','s':
		{
			CTXDataType = CTX_STRING;
		}
		
		case 'B','b':
		{
			CTXDataType = CTX_BOOL;
		}
		
		case 'I','i':
		{
			CTXDataType = CTX_INT;
		}
		
		case 'F','f':
		{
			CTXDataType = CTX_FLOAT;
		}
		
		case 'P','p':
		{
			CTXDataType = CTX_PTR_STRING;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXDataType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	decl String:sVariable[64], String:sClassName[64], String:sProposedValue[64];
	GetCmdArg(3, sVariable, sizeof(sVariable));
	GetCmdArg(4, sClassName, sizeof(sClassName));
	GetCmdArg(5, sProposedValue, sizeof(sProposedValue));
	
	switch(CTX_Set(CTXType, CTXDataType, sVariable, sClassName, sProposedValue))
	{
		case 0:
		{
			decl String:sArgString[512];
			GetCmdArgString(sArgString, sizeof(sArgString));
			ReplyToCommand(client, "\x04[CTX]\x03 Query Failed with: \x04%s\x03.", sArgString);
		}
		
		case 1:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 The Value of \x04%s\x03 is now \x04%s\x03.", sVariable, sProposedValue);
		}
	}
	return Plugin_Handled;
}

public Action:OnCTXResetClass(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 sm_ctx_reset CTXType CTXClassName");
		return Plugin_Handled;
	}
	
	decl String:sArg[64];
	
	if(GetCmdArg(1, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXType;
	
	switch(sArg[4])
	{
		case 'P','p':
		{
			if(sArg[10] == '\0')
			{
				CTXType = CTX_PLAYER;
			}
			else
			{
				CTXType = CTX_PLAYER_TEAM2;
			}
		}
		
		case 'W','w':
		{
			CTXType = CTX_WEAPON;
		}
		
		case 'O','o':
		{
			CTXType = CTX_OBJECT;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	decl String:sCTXClass[64];
	GetCmdArg(2, sCTXClass, sizeof(sCTXClass));
	
	switch(CTX_Reset(CTXType, sCTXClass))
	{
		case 0:
		{
			decl String:sArgString[512];
			GetCmdArgString(sArgString, sizeof(sArgString));
			ReplyToCommand(client, "\x04[CTX]\x03 Query Failed with: \x04%s\x03.", sArgString);
		}
		
		case 1:
		{
			ReplyToCommand(client, "\x04[CTX] %s\x03 has been \x04Reset\x03.", sCTXClass);
		}
	}
	return Plugin_Handled;
}

public Action:OnCTXResetType(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 sm_ctx_resettype CTXType");
		return Plugin_Handled;
	}
	
	decl String:sArg[64];
	
	if(GetCmdArg(1, sArg, sizeof(sArg)) < 5)
	{
		ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
		return Plugin_Handled;
	}
	
	new CTXType;
	
	switch(sArg[4])
	{
		case 'P','p':
		{
			if(sArg[10] == '\0')
			{
				CTXType = CTX_PLAYER;
			}
			else
			{
				CTXType = CTX_PLAYER_TEAM2;
			}
		}
		
		case 'W','w':
		{
			CTXType = CTX_WEAPON;
		}
		
		case 'O','o':
		{
			CTXType = CTX_OBJECT;
		}
		
		default:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Invalid Input for CTXType: \x04%s\x03.", sArg);
			return Plugin_Handled;
		}
	}
	
	switch(CTX_ResetAll(CTXType))
	{
		case 0:
		{
			ReplyToCommand(client, "\x04[CTX]\x03 Query Failed with: \x04%s\x03.", sArg);
		}
		
		case 1:
		{
			ReplyToCommand(client, "\x04[CTX] \x04%s\x03 has been \x04Reset\x03.", sArg);
		}
	}
	return Plugin_Handled;
}