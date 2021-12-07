public Action:OnClientKickedPre_ServerWhitelistAdvanced( client, bool:isFromBlacklistCache, const String:szSteamId[], const String:szIP[] )
{
	//Returning Action:Plugin_Handled prevent the player from getting kick; THIS CODE BLOCKS EVERYTHING
	return Action:Plugin_Handled;
}