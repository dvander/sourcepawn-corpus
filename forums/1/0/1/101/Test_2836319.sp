public void OnSpecJoinTarget(int spectator, int NewTaget)
{
	PrintToChat(NewTaget , "\x05%N has join your channel" , spectator);
}

public void OnSpecLeftTarget(int spectator, int OldTaget)
{
	PrintToChat(OldTaget , "\x03%N has left your channel" , spectator);
}