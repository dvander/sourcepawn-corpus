#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = {
	name = "Calculator",
	author = "Scone",
	description = "Calculates maths and stuff.",
	version = PLUGIN_VERSION
};

public OnPluginStart() {
	RegConsoleCmd("sm_calc", CalcCmd, "sm_calc <expression>");
	CreateConVar("smcalc_version", PLUGIN_VERSION, "Calculator version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:CalcCmd(client, args) {

	if(args == 0) {
		ReplyToCommand(client, "[Calc] No expression provided.");
		return Plugin_Handled;
	}
	
	new String:cmd[512];
	GetCmdArgString(cmd, sizeof(cmd));
	
	new ossPos = -1, ssPos = 0, c;
	while((c = cmd[++ossPos]) != 0) if(c != ' ') cmd[ssPos++] = c;
	cmd[ssPos] = 0;
	
	if(strlen(cmd) > sizeof(cmd)-2) {
		ReplyToCommand(client, "[Calc] Syntax error: expression too long.");
		return Plugin_Handled;
	}
	
	new cmdPos = 0, Float:num, op, tType, oQueuePos = 0, opStackPos = 0;
	new outputQueue[128][2];
	new opStack[64];
	
	cmdPos = 0;
	
	while((tType = ReadToken(cmd, cmdPos, num, op)) != 0) {
		
		if(tType == -1) {
			ReplyToCommand(client, "[Calc] Syntax error: token too long.");
			return Plugin_Handled;
			
		} else if(tType == -2) {
			ReplyToCommand(client, "[Calc] Syntax error: all functions require brackets. Including: random(), pi(), e().");
			return Plugin_Handled;
		
		} else if(tType == 1) {
			
			new thisPrec, thisAssoc, thisType;
			if(FindOp(op, thisPrec, thisAssoc, thisType)) {
			
				while(opStackPos > 0) {
					new topPrec, topAssoc, topType;
					FindOp(opStack[opStackPos - 1], topPrec, topAssoc, topType);
					
					if((thisAssoc == 1 && thisPrec <= topPrec) || (thisAssoc == 2 && thisPrec < topPrec)) {
						opStackPos--;
						outputQueue[oQueuePos][0] = 1;
						outputQueue[oQueuePos][1] = opStack[opStackPos];
						oQueuePos++;
					} else {
						break;
					}
				}
				
				opStack[opStackPos++] = op;
				
			} else if(op == '(') {
				opStack[opStackPos++] = op;
				
			} else if(op == ')') {
			
				new bool:found = false;
			
				while(--opStackPos >= 0) {
					if(opStack[opStackPos] == '(') {
						found = true;
						break;
					}
					outputQueue[oQueuePos][0] = 1;
					outputQueue[oQueuePos][1] = opStack[opStackPos];
					oQueuePos++;
				}
				
				if(!found) {
					ReplyToCommand(client, "[Calc] Mismatched brackets.");
					return Plugin_Handled;
				}
				
				if(opStackPos > 0 && opStack[opStackPos - 1] >= 256) {
					outputQueue[oQueuePos][0] = 3;
					outputQueue[oQueuePos][1] = opStack[--opStackPos];
					oQueuePos++;
				}
				
			} else if(op == ',') {
			
				new bool:found = false;
			
				while(--opStackPos >= 0) {
					if(opStack[opStackPos] == '(') {
						found = true;
						opStackPos++;
						break;
					}
					outputQueue[oQueuePos][0] = (opStack[opStackPos] < 256 ? 1 : 3);
					outputQueue[oQueuePos][1] = opStack[opStackPos];
					oQueuePos++;
				}
				
				if(!found) {
					ReplyToCommand(client, "[Calc] Misplaced comma (or mismatched brackets).");
					return Plugin_Handled;
				}
				
			} else {
				ReplyToCommand(client, "[Calc] Unknown operator '%c'.", op);
				return Plugin_Handled;
			}
			
		} else if(tType == 3) {
			opStack[opStackPos++] = op;
		
		} else {
			outputQueue[oQueuePos][0] = 2;
			outputQueue[oQueuePos][1] = any:num;
			oQueuePos++;
		}
		
		if(oQueuePos >= sizeof(outputQueue)) {
			ReplyToCommand(client, "[Calc] Stack overflow - expression too long.");
			return Plugin_Handled;
		}
		
		if(opStackPos >= sizeof(opStack)) {
			ReplyToCommand(client, "[Calc] Stack overflow - too many operators.");
			return Plugin_Handled;
		}
	}
	
	while(opStackPos-- > 0) {
		op = opStack[opStackPos];
		if(op == '(' || op == ')') {
			ReplyToCommand(client, "[Calc] Mismatched brackets.");
			return Plugin_Handled;
		}
		
		outputQueue[oQueuePos][0] = (op < 256 ? 1 : 3);
		outputQueue[oQueuePos][1] = op;
		oQueuePos++;
	}
	
	new Float:execStack[32];
	new execStackPos = 0;
	
	for(new i = 0; i < oQueuePos; i++) {
		if(outputQueue[i][0] == 1) {
		
			if(outputQueue[i][1] >= 256) {
				ReplyToCommand(client, "[Calc] Internal error: function '%d' mistaken for operator.", outputQueue[i][1]);
				return Plugin_Handled;
			}
		
			if(execStackPos < 2) {
				ReplyToCommand(client, "[Calc] Syntax error: operator '%c' requires two operands.", outputQueue[i][1]);
				return Plugin_Handled;
			}
			
			new thisPrec, thisAssoc, thisType;
			
			if(FindOp(outputQueue[i][1], thisPrec, thisAssoc, thisType)) {
			
				new Float:b = execStack[--execStackPos];
				new Float:a = execStack[--execStackPos];
				
				switch(thisType) {
					case 1: {
						execStack[execStackPos++] = a + b;
					}
					case 2: {
						execStack[execStackPos++] = a - b;
					}
					case 3: {
						execStack[execStackPos++] = a * b;
					}
					case 4: {
						execStack[execStackPos++] = a / b;
					}
					case 5: {
						execStack[execStackPos++] = float(RoundToNearest(a) % RoundToNearest(b));
					}
					case 6: {
						execStack[execStackPos++] = Pow(a, b);
					}
					default: {
						ReplyToCommand(client, "[Calc] Internal Error: unknown operation type %d.", thisType);
						return Plugin_Handled;
					}
				}
			} else {
				ReplyToCommand(client, "[Calc] Unknown operator '%c'.", outputQueue[i][1]);
				return Plugin_Handled;
			}
			
		} else if(outputQueue[i][0] == 2) {
			execStack[execStackPos++] = Float:outputQueue[i][1];
		
		} else if(outputQueue[i][0] == 3) {
		
			new fNum = outputQueue[i][1];
			
			switch(fNum) {
				case 257: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for sqrt.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Pow(a, 0.5);
				}
				case 258: {
					if(execStackPos < 2) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for root.");
						return Plugin_Handled;
					}
					
					new Float:b = execStack[--execStackPos];
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Pow(b, 1/a);
				}
				case 259: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for log.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Logarithm(a, 10.0);
				}
				case 260: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for ln.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Logarithm(a, 2.718281828);
				}
				case 261: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for sin.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Sine(a);
				}
				case 262: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for cos.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Cosine(a);
				}
				case 263: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for tan.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = Tangent(a);
				}
				case 264: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for asin.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = ArcSine(a);
				}
				case 265: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for acos.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = ArcCosine(a);
				}
				case 266: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for atan.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = ArcTangent(a);
				}
				case 267: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for degtorad.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = DegToRad(a);
				}
				case 268: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for radtodeg.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = RadToDeg(a);
				}
				case 269: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for round.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = float(RoundToNearest(a));
				}
				case 270: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for ceil.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = float(RoundToCeil(a));
				}
				case 271: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for floor.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = float(RoundToFloor(a));
				}
				case 272: {
					execStack[execStackPos++] = GetURandomFloat();
				}
				case 273: {
					if(execStackPos < 1) {
						ReplyToCommand(client, "[Calc] Syntax error: incorrect number of args for abs.");
						return Plugin_Handled;
					}
					
					new Float:a = execStack[--execStackPos];
					execStack[execStackPos++] = FloatAbs(a);
				}
				case 274: {
					execStack[execStackPos++] = 2.718281828;
				}
				case 275: {
					execStack[execStackPos++] = 3.14159265358;
				}
				case 256: {
					ReplyToCommand(client, "[Calc] Syntax error: invalid function name.");
					return Plugin_Handled;
				}
				default: {
					ReplyToCommand(client, "[Calc] Internal Error: unknown function type %d.", fNum);
					return Plugin_Handled;
				}
			}
			
		} else {
			ReplyToCommand(client, "[Calc] Internal Error: unknown token type %d.", outputQueue[i][0]);
			return Plugin_Handled;
		}
	}
	
	if(execStackPos != 1) {
		ReplyToCommand(client, "[Calc] Syntax error.");
	} else {
	
		decl String:result[32];
		Format(result, sizeof(result), "%.6f", execStack[0]);
		for(new i = strlen(result) - 1; i > 0; i--) {
			if(result[i] == '0') result[i] = 0;
			else break;
		}
		
		if(strlen(result) > 7) {
			ReplyToCommand(client, "[Calc] Warning: Result may contain floating point inaccuracies.");
		}
	
		ReplyToCommand(client, "[Calc] Result: %s", result);
	}
	
	return Plugin_Handled;
}

bool:FindOp(op, &precedence, &assoc, &optype) {
	
	switch(op) {
		case '+': {
			precedence = 3;
			assoc = 1;
			optype = 1;
		}
		case '-': {
			precedence = 3;
			assoc = 1;
			optype = 2;
		}
		case '*': {
			precedence = 4;
			assoc = 1;
			optype = 3;
		}
		case '/': {
			precedence = 4;
			assoc = 1;
			optype = 4;
		}
		case '%': {
			precedence = 4;
			assoc = 1;
			optype = 5;
		}
		case '^': {
			precedence = 5;
			assoc = 2;
			optype = 6;
		}
		default: {
			return false;
		}
	}
	return true;
}

FindFunc(const String:name[]) {
	if(StrEqual(name, "sqrt"))
		return 257;
	else if(StrEqual(name, "root"))
		return 258;
	else if(StrEqual(name, "log"))
		return 259;
	else if(StrEqual(name, "ln"))
		return 260;
	else if(StrEqual(name, "sin"))
		return 261;
	else if(StrEqual(name, "cos"))
		return 262;
	else if(StrEqual(name, "tan"))
		return 263;
	else if(StrEqual(name, "asin"))
		return 264;
	else if(StrEqual(name, "acos"))
		return 265;
	else if(StrEqual(name, "atan"))
		return 266;
	else if(StrEqual(name, "degtorad"))
		return 267;
	else if(StrEqual(name, "radtodeg"))
		return 268;
	else if(StrEqual(name, "round"))
		return 269;
	else if(StrEqual(name, "ceil"))
		return 270;
	else if(StrEqual(name, "floor"))
		return 271;
	else if(StrEqual(name, "random"))
		return 272;
	else if(StrEqual(name, "abs"))
		return 273;
	else if(StrEqual(name, "e"))
		return 274;
	else if(StrEqual(name, "pi"))
		return 275;
	else {
		return 256;
	}
}

ReadToken(const String:source[], &pos, &Float:num, &op) {

	new c = source[pos];
	if(c == 0) return 0;
	
	decl String:tmp[20];
	
	if(IsCharNumeric(c) || c == '.' || c == '_') {
		new i = 0;
		while((c = source[pos]) != 0 && i < sizeof(tmp)-2 && (IsCharNumeric(c) || c == '.' || c == '_')) {
			if(c == '_') c = '-';
			tmp[i++] = c;
			pos++;
		}
		if(i > sizeof(tmp)-3) return -1;
		tmp[i] = 0;
		num = StringToFloat(tmp);
		return 2;
	}
	
	if(IsCharAlpha(c)) {
		new i = 0;
		while((c = source[pos]) != 0 && i < sizeof(tmp)-2 && IsCharAlpha(c)) {
			tmp[i++] = c;
			pos++;
		}
		if(i > sizeof(tmp)-3) return -1;
		if(c != '(') return -2;
		tmp[i] = 0;
		op = FindFunc(tmp);
		return 3;
	}
	
	op = c;
	pos++;
	return 1;
}