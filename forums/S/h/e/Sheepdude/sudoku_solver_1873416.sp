#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"
#define ALL_CANDIDATES 511
#define CANDIDATE_SOLVED (1 << 9)
#define ROWS 9

new g_Candidates[ROWS][ROWS];

public Plugin:myinfo = 
{
	name = "Sudoku Solver",
	author = "Sheepdude",
	description = "Harness the power of srcds to solve your sudoku puzzles!",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

/******
 *Load*
*******/

public OnPluginStart()
{
	CreateConVar("sudoku_solver_version", PLUGIN_VERSION, "Plugin version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("sudoku_solve", Solve);
}

/**********
 *Commands*
***********/

public Action:Solve(client, args)
{
	if(!Populate())
	{
		ReplyToCommand(client, "[Sudoku Solver] Error reading from sudoku.txt.");
		return Plugin_Handled;
	}

	new count = 0;
	new bool:failure = false;
	while(!SolutionFound())
	{
		CheckGrid();
		if(count == CountSolvedCandidates())
		{
			failure = true;
			break;
		}
		count = CountSolvedCandidates();
	}
	
	if(failure)
		ReplyToCommand(client, "Solution could not be found.");
	else
	{
		ReplyToCommand(client, "Solution found! Logged to sudoku_solution.txt\n");
		decl String:line[16];
		new flag;
		for(new i = 0; i < ROWS; i++)
		{
			flag = FlagToInt(g_Candidates[i][0] << 1);
			Format(line, 16, "  %i", g_Candidates[i][0] & CANDIDATE_SOLVED > 1 ? flag : 0);
			for(new k = 1; k < ROWS; k++)
			{
				flag = FlagToInt(g_Candidates[i][k] << 1);
				Format(line, 16, "%s%i", line, g_Candidates[i][k] & CANDIDATE_SOLVED > 1 ? flag : 0);
			}
			LogToFile("sudoku_solution.txt", line);
			ReplyToCommand(client, line);
		}
	}
	return Plugin_Handled;
}

/********
 *Plugin*
*********/

bool:Populate()
{	
	// Check that sudoku.txt exists
	if(!FileExists("sudoku.txt"))
		return false;
	
	// Open sudoku.txt
	new Handle:File = OpenFile("sudoku.txt", "r");
	if(File == INVALID_HANDLE)
		return false;
		
	// Clear candidate array
	for(new i = 0; i < ROWS; i++)
		for(new k = 0; k < ROWS; k++)
			g_Candidates[i][k] = ALL_CANDIDATES;
	
	// Populate candidate array
	decl String:line[16];
	decl String:char[2];
	new linecount = 0;
	while(!IsEndOfFile(File) && linecount < ROWS)
	{
		ReadFileLine(File, line, 16);
		TrimString(line);
		for(new x = 0; x < ROWS; x++)
		{
			Format(char, 2, "%c", line[x]);
			if(StringToInt(char) > 0)
				g_Candidates[linecount][x] = 1 << (StringToInt(char) - 1) | CANDIDATE_SOLVED;
		}
		linecount++;
	}
	CloseHandle(File);
	if(linecount < ROWS)
		return false;
	return true;
}

CheckGrid()
{
	for(new i = 0; i < ROWS; i++)
		for(new k = 0; k < ROWS; k++)
			if(g_Candidates[i][k] & CANDIDATE_SOLVED > 0)
			{
				RemoveCandidate(g_Candidates[i][k], i, k);
				CheckSolvedCandidates();
			}
}

/************
 *Candidates*
*************/

RemoveCandidate(candidate, row, col)
{
	for(new i = 0; i < ROWS; i++)
	{
		if(g_Candidates[row][i] & CANDIDATE_SOLVED == 0)
			g_Candidates[row][i] &= ~candidate;
		if(g_Candidates[i][col] & CANDIDATE_SOLVED == 0)
			g_Candidates[i][col] &= ~candidate;
	}
	
	if(row < 3)
		row = 0;
	else if(row < 6)
		row = 3;
	else
		row = 6;
	
	if(col < 3)
		col = 0;
	else if(col < 6)
		col = 3;
	else
		col = 6;
	
	for(new m = row; m < row + 3; m++)
		for(new n = col; n < col + 3; n++)
			if(g_Candidates[m][n] & CANDIDATE_SOLVED == 0)
				g_Candidates[m][n] &= ~candidate;
}

CheckSolvedCandidates()
{
	new count;
	for(new i = 0; i < ROWS; i++)
		for(new k = 0; k < ROWS; k++)
		{
			if(g_Candidates[i][k] & CANDIDATE_SOLVED == 0)
			{
				count = 0;
				for(new num = 0; num < ROWS; num++)
				{
					if(g_Candidates[i][k] & (1 << num) > 0)
						count++;
				}
				if(count == 1)
					g_Candidates[i][k] |= CANDIDATE_SOLVED;
			}
		}
}

CountSolvedCandidates()
{
	new count = 0;
	for(new i = 0; i <= ROWS - 1; i++)
		for(new k = 0; k <= ROWS - 1; k++)
			if(g_Candidates[i][k] & CANDIDATE_SOLVED > 0)
				count++;
	return count;
}

bool:SolutionFound()
{
	for(new i = 0; i < ROWS; i++)
		for(new k = 0; k < ROWS; k++)
			if(g_Candidates[i][k] & CANDIDATE_SOLVED == 0)
				return false;
	return true;
}

/********
 *Stocks*
*********/

stock FlagToInt(flag)
{
	for(new i = 0; i < 32; i++)
		if(flag & 1 << i)
			return i;
	return -1;
}