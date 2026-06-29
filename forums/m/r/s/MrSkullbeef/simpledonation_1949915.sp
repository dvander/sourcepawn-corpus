#define Plugin_Version "1.0"
#define MOTDPANEL_TYPE_TEXT 0
#define MOTDPANEL_TYPE_INDEX 1
#define MOTDPANEL_TYPE_URL 2
#define MOTDPANEL_TYPE_FILE 3
#include <sourcemod>

new Handle:DonationURL;

public Plugin:myinfo =
{
	name = "Simple MOTD Donation",
	author = "Mr.Skullbeef",
	description = "Simple plugin for letting players donate through MOTD.",
	version = Plugin_Version,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_donate", Command_Donate, "Show donation page in MOTD");
	DonationURL = CreateConVar("sm_donation_url", "http://yourdonationlink.com", "Set this to the url of your donation page.");
}

public Action:Command_Donate(client, args)
{
	new String:MOTDURL[128];
	GetConVarString(DonationURL, MOTDURL, 127);

	ShowMOTDPanel(client, "Command_Donate", MOTDURL, MOTDPANEL_TYPE_URL)
	return Plugin_Handled;
}
