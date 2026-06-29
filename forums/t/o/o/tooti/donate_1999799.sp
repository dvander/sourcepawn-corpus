#pragma semicolon 1

#include <sourcemod>

new Handle:g_paypalemail = INVALID_HANDLE;
new Handle:g_currency = INVALID_HANDLE;
new Handle:g_mode = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Donate",
	author = "FreakyLike",
	description = "Simple plugin that allows players to donate ingame via PayPal.",
	version = "1.1",
	url = "http://nastygaming.de"
};

public OnPluginStart()
{
	g_paypalemail = CreateConVar("sm_paypal_email", "your-paypal@mail.com", "PayPal E-Mail Address \nEnter your PayPal E-Mail Address here.");
	g_currency = CreateConVar("sm_paypal_currency", "EUR", "PayPal Currency \nSet your Currency here. \nAll Currencies: EUR, USD, CHF.");
	g_mode = CreateConVar("sm_donate_command", "donate", "Donate Command \nChoose your command for the donations here.");
	AutoExecConfig(true, "plugin.donate");
	
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
	if (i > 0 && i < MaxClients && IsClientConnected(i) && IsClientInGame(i))
	{
		if(args == 1)
		{
			new String:donateurl[192];
			new String:buffer[192];
			new String:amount[192];
			new String:currency[192];
			GetCmdArg(1, amount, sizeof(amount));
			GetConVarString(g_paypalemail, donateurl, sizeof(donateurl));
			GetConVarString(g_currency, currency, sizeof(currency));
			Format(buffer, sizeof(buffer), "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&lc=US&amount=%s.00&currency_code=%s&no_note=0", donateurl, amount, currency);
			ShowMOTDPanel(i, "PayPal Donation", buffer, MOTDPANEL_TYPE_URL);
		}
		else
		{
			new String:Command[32];
			GetConVarString(g_mode, Command, sizeof(Command));
			PrintToChat(i, "\x01Usage: !%s <amount>",Command);
			PrintToConsole(i,"Usage: sm_%s <amount>",Command);
		}
	}
	return Plugin_Handled;
}