#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#include <autoexecconfig>

new Handle:g_paypalemail = INVALID_HANDLE;
new Handle:g_mode = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Donate",
	author = "FreakyLike (Modified by ReZy)",
	description = "Simple plugin that allows players to donate ingame via PayPal.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("plugin.donate");
	g_paypalemail = AutoExecConfig_CreateConVar("sm_paypal_email", "your-paypal@mail.com", "PayPal E-Mail Address \nEnter your PayPal E-Mail Address here.");
	g_mode = AutoExecConfig_CreateConVar("sm_donate_command", "donate", "Donate Command \nChoose your command for the donations here.");
	AutoExecConfig(true, "plugin.donate");
	AutoExecConfig_CleanFile();
	
	new String:Command[32];
	new String:buffer[32];
	GetConVarString(g_mode, Command, sizeof(Command));
	Format(buffer, sizeof(buffer), "sm_%s", Command);
	RegConsoleCmd(buffer, command_donate, "Donate URL");
}

public OnConfigsExecuted()
{
	new String:valid[100];
	GetConVarString(g_paypalemail, valid, sizeof(valid));
	if(!StrContains(valid, "@", true))
	{
		SetFailState("E-Mail is not valid!");
	}
}

public Action:command_donate(i, args)
{
	if (Client_IsValid(i))
	{
		if(args > 0 || args <= 1)
		{
			new String:donateurl[192];
			new String:buffer[192];
			new String:amount[192];
			GetCmdArg(1, amount, sizeof(amount));
			GetConVarString(g_paypalemail, donateurl, sizeof(donateurl));
			Format(buffer, sizeof(buffer), "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&lc=US&amount=%s.00&currency_code=USD&no_note=0", donateurl, amount);
			ShowMOTDPanel(i, "PayPal Donation", buffer, MOTDPANEL_TYPE_URL);
		}
		else
		{
			new String:Command[32];
			GetConVarString(g_mode, Command, sizeof(Command));
			PrintToChat(i, "\x01Usage: !%s <amount (usd)>",Command);
			PrintToConsole(i,"Usage: sm_%s <amount (usd)>",Command);
		}
	}
	return Plugin_Handled;
}