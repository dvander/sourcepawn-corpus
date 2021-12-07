#include <sourcemod>
#include "empires"

new BETicks = 0;
new NFTicks = 0;
new UBETicks = 0;
new UNFTicks = 0;

new BERes = 0;
new NFRes = 0;
new UBERes = 0;
new UNFRes = 0;

public Plugin:myinfo = 
{
	name = "Empires Tools",
	author = "Theowningone",
	description = "Empires Tools",
	version = "1.1",
	url = "http://www.theowningone.info/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_setbreinf", Command_setbreinf, ADMFLAG_ROOT);
	RegAdminCmd("sm_setnreinf", Command_setnreinf, ADMFLAG_ROOT);
	RegAdminCmd("sm_givebreinf", Command_givebreinf, ADMFLAG_ROOT);
	RegAdminCmd("sm_givenreinf", Command_givenreinf, ADMFLAG_ROOT);
	RegAdminCmd("sm_setbres", Command_setbres, ADMFLAG_ROOT);
	RegAdminCmd("sm_setnres", Command_setnres, ADMFLAG_ROOT);
	RegAdminCmd("sm_givebres", Command_givebres, ADMFLAG_ROOT);
	RegAdminCmd("sm_givenres", Command_givenres, ADMFLAG_ROOT);
	RegAdminCmd("sm_getbres", Command_getbres, ADMFLAG_ROOT);
	RegAdminCmd("sm_getnres", Command_getnres, ADMFLAG_ROOT);
	RegAdminCmd("sm_uticks", Command_uticks, ADMFLAG_ROOT);
	RegAdminCmd("sm_ures", Command_ures, ADMFLAG_ROOT);
	RegAdminCmd("sm_ubticks", Command_ubticks, ADMFLAG_ROOT);
	RegAdminCmd("sm_ubres", Command_ubres, ADMFLAG_ROOT);
	RegAdminCmd("sm_unticks", Command_unticks, ADMFLAG_ROOT);
	RegAdminCmd("sm_unres", Command_unres, ADMFLAG_ROOT);
}

public Action:Command_setbreinf(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !setbreinf <amount>")
		PrintToConsole(client, "Proper Usage: sm_setbreinf <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	SetBEReinforcements(amount);
	return Plugin_Handled;
}

public Action:Command_setnreinf(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !setnreinf <amount>")
		PrintToConsole(client, "Proper Usage: sm_setnreinf <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	SetNFReinforcements(amount);
	return Plugin_Handled;
}
	
public Action:Command_givebreinf(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !givebreinf <amount>")
		PrintToConsole(client, "Proper Usage: sm_givebreinf <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	new was = GetBEReinforcements();
	amount = amount + was;
	SetBEReinforcements(amount);
	return Plugin_Handled;
}

public Action:Command_givenreinf(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !givenreinf <amount>")
		PrintToConsole(client, "Proper Usage: sm_givenreinf <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	new was = GetNFReinforcements();
	amount = amount + was;
	SetNFReinforcements(amount);
	return Plugin_Handled;
}

public Action:Command_setbres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !setbres <amount>")
		PrintToConsole(client, "Proper Usage: sm_setbres <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	SetBEResources(amount);
	return Plugin_Handled;
}

public Action:Command_setnres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !setnres <amount>")
		PrintToConsole(client, "Proper Usage: sm_setnres <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	SetNFResources(amount);
	return Plugin_Handled;
}

public Action:Command_givebres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !givebres <amount>")
		PrintToConsole(client, "Proper Usage: sm_givebres <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	new was = GetBEResources();
	amount = amount + was;
	SetBEResources(amount);
	return Plugin_Handled;
}

public Action:Command_givenres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !givenres <amount>")
		PrintToConsole(client, "Proper Usage: sm_givenres <amount>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new amount = StringToInt(argraw);
	new was = GetNFResources();
	amount = amount + was;
	SetNFResources(amount);
	return Plugin_Handled;
}

public Action:Command_getbres(client, args)
{
	new amount = GetBEResources();
	PrintToChat(client, "BE Resources: %i", amount);
}
	
public Action:Command_getnres(client, args)
{
	new amount = GetNFResources();
	PrintToChat(client, "NF Resources: %i", amount);
}




/****************************
* --> Unlimited Tickets <-- *
****************************/
public Action:Command_uticks(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !uticks <0|1>")
		PrintToConsole(client, "Proper Usage: sm_uticks <0|1>");
		return Plugin_Handled;
	}
	Command_ubticks(client, args);
	Command_unticks(client, args);
	return Plugin_Handled;
}

public Action:Command_ubticks(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !ubticks <0|1>")
		PrintToConsole(client, "Proper Usage: sm_ubticks <0|1>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new arg = StringToInt(argraw);
	if(arg == 1 && UBETicks == 0)
	{
		BETicks = GetBEReinforcements();
		UBETicks = 1;
	}
	if(arg == 0 && UBETicks == 1)
	{
		UBETicks = 0;
		SetBEReinforcements(BETicks);
	}
	return Plugin_Handled;
}

public Action:Command_unticks(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !unticks <0|1>")
		PrintToConsole(client, "Proper Usage: sm_unticks <0|1>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new arg = StringToInt(argraw);
	if(arg == 1 && UNFTicks == 0)
	{
		NFTicks = GetNFReinforcements();
		UNFTicks = 1;
	}
	if(arg == 0 && UNFTicks == 1)
	{
		UNFTicks = 0;
		SetNFReinforcements(NFTicks);
	}
	return Plugin_Handled;
}




/******************************
* --> Unlimited Resources <-- *
******************************/
public Action:Command_ures(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !ures <0|1>")
		PrintToConsole(client, "Proper Usage: sm_ures <0|1>");
		return Plugin_Handled;
	}
	Command_ubres(client, args);
	Command_unres(client, args);
	return Plugin_Handled;
}

public Action:Command_ubres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !ubres <0|1>")
		PrintToConsole(client, "Proper Usage: sm_ubres <0|1>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new arg = StringToInt(argraw);
	if(arg == 1 && UBERes == 0)
	{
		BERes = GetBEResources();
		UBERes = 1;
	}
	if(arg == 0 && UBERes == 1)
	{
		UBERes = 0;
		SetBEResources(BERes);
	}
	return Plugin_Handled;
}

public Action:Command_unres(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "Proper Usage: !unres <0|1>")
		PrintToConsole(client, "Proper Usage: sm_unres <0|1>");
		return Plugin_Handled;
	}
	decl String:argraw[64];
	GetCmdArg(1, argraw, sizeof(argraw));
	new arg = StringToInt(argraw);
	if(arg == 1 && UNFRes == 0)
	{
		NFRes = GetNFResources();
		UNFRes = 1;
	}
	if(arg == 0 && UNFRes == 1)
	{
		UNFRes = 0;
		SetNFResources(NFRes);
	}
	return Plugin_Handled;
}




/*******************************
* --> Do the Resource Work <-- *
*******************************/

public OnGameFrame()
{
	if(UBETicks == 1)
	{
		SetBEReinforcements(1337);
	}
	if(UNFTicks == 1)
	{
		SetNFReinforcements(1337);
	}
	if(UBERes == 1)
	{
		SetBEResources(9999);
	}
	if(UNFRes == 1)
	{
		SetNFResources(9999);
	}
}




/**********************************************
* --> Stop Unlimited Resources on New Map <-- *
**********************************************/
public OnMapStart()
{
	UBERes = 0;
	UNFRes = 0;
	UBETicks = 0;
	UNFTicks = 0;
}