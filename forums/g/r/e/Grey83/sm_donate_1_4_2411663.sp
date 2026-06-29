#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define PLUGIN_VERSION "1.4 (rewrited by Grey83)"

Handle g_paypalemail = INVALID_HANDLE;
Handle g_currency = INVALID_HANDLE;
Handle g_mode = INVALID_HANDLE;
bool bCSGO;

public Plugin myinfo =
{
	name = "Donate",
	author = "FreakyLike, Trinia",
	description = "Simple plugin that allows players to donate ingame via PayPal.",
	version = PLUGIN_VERSION,
	url = "http://nastygaming.de"
};

public void OnPluginStart()
{
	g_paypalemail = CreateConVar("sm_paypal_email", "your-paypal@mail.com", "PayPal E-Mail Address\nEnter your PayPal E-Mail Address here.");
	g_currency = CreateConVar("sm_paypal_currency", "EUR", "PayPal Currency\nSet your Currency here.\nAll Currencies: EUR, USD, CHF.");
	g_mode = CreateConVar("sm_donate_command", "donate", "Donate Command\nChoose your command for the donations here.");
	CreateConVar("sm_donate_version", PLUGIN_VERSION, "Donations Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "plugin.donate");
	
	char buffer[32];
	GetConVarString(g_mode, buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "sm_%s", buffer);
	RegConsoleCmd(buffer, command_donate, "Donate URL");

	if(GetEngineVersion() == Engine_CSGO) bCSGO = true;
}

public void OnConfigsExecuted()
{
	char valid[100];
	GetConVarString(g_paypalemail, valid, sizeof(valid));
	if(StrContains(valid, "@", true) < 1) SetFailState("E-Mail is not valid!");
}

public Action command_donate(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
	}
	else if(client < MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(!args)
		{
			char Command[32];
			GetConVarString(g_mode, Command, sizeof(Command));
			PrintToChat(client, "\x01Usage: !%s <amount>",Command);
			PrintToConsole(client,"Usage: sm_%s <amount>",Command);
		}
		else
		{
			char donateurl[192];
			char buffer[192];
			char amount[192];
			char currency[192];
			char title[32];
			GetCmdArg(1, amount, sizeof(amount));
			float amt = StringToFloatEx(amount, amt);
			if(amt >= 0.1)
			{
				GetConVarString(g_paypalemail, donateurl, sizeof(donateurl));
				GetConVarString(g_currency, currency, sizeof(currency));
				if (bCSGO) Format(buffer, sizeof(buffer), "http://nastygaming.de/webscript.html?web=https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&lc=US&amount=%.2f&currency_code=%s&no_note=0", donateurl, amt, currency);
				else Format(buffer, sizeof(buffer), "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=%s&lc=US&amount=%,2f&currency_code=%s&no_note=0", donateurl, amt, currency);
				Format(title, sizeof(buffer), "PayPal Donation (%s %.2f)", currency, amt);
				ShowMOTDPanel(client, title, buffer, MOTDPANEL_TYPE_URL);
			}
			else PrintToChat(client, "\x01Zero - is too big donation =)");
		}
	}
	return Plugin_Handled;
}