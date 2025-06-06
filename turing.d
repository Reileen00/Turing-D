import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.ascii;
import std.array;
import std.exception;
import std.conv;
import std.range;
import std.typecons;
import core.stdc.stdlib;

enum Step{L,R}
alias State=string;
alias Symbol=string;

struct Turd{
  State current;
  Symbol read;
  Symbol write;
  Step step;
  State next;
}
struct Machine{
  Symbol[] tape;
  ulong head;
  State state;
  bool next(Turd[] program){
    foreach(turd;program){
      if(turd.current==state && turd.read==tape[head]){
        tape[head]=turd.write;
        final switch (turd.step){
          case Step.L:
            if(head==0)head=tape.length-1;
            else head-=1;
            break;
          case Step.R:
            head=(head+1)%tape.length;
            break;
        }
        state=turd.next;
        return true;
      }
    }
    return false;
  }
  void dump_tape(){
    foreach(cell;tape)write(cell,' ');
    writeln();
  }
  void debug_dump(){
    writeln("STATE: ",state);
    dump_tape();
    foreach(i,cell;tape){
      if(i==head)write('^');
      for(int j=0;j<cell.length;j++)write(' ');
      if(i!=head)write(' ');
    }
  }
}
Turd parseTurd(string filepath,Tuple!(int,"index",string,"value")s){
  auto tokens=s.value.split!isWhite.map!(x=>x.strip).array;
  if(tokens.length!=5){
    writeln(filepath,":",s.index,":A single turd is expecteed to have 5 tokens");
    exit(1);
  }
  immutable int CURRENT=0;
  immutable int READ=1;
  immutable int WRITE=2;
  immutable int STEP=3;
  immutable int NEXT=4;

  Turd turd;
  turd.current=tokens[CURRENT];
  turd.read=tokens[READ];
  turd.write=tokens[WRITE];
  switch(tokens[STEP]){
    case "L":
      turd.step=Step.L;
      break;
    case "R":
      turd.step=Step.R;
      break;
    default:
      writeln(filepath,":",s[0],": `",tokens[STEP],"`is not a correct step.");
      exit(1);
  }
  turd.next=tokens[NEXT];
  return turd;
}
void usage(File stream){
  stream.writeln("Usage:turd[OPTIONS] <input.turd> <input.tape>");
  stream.writeln("OPTIONS:");
  stream.writeln("  --help|-h            print this help to stdout and exit with 0 exit code");
  stream.writeln("  --state|-s[STATE]    start from a specific initial state(default: BEGIN)");
  stream.writeln("  --head|-p[POSITION]  start from a specific head position (default: 0)");
  stream.writeln("  --non-interactively  execute the program non-interactively");
}
int main(string[] args){
  bool non_interactively = false;
  Machine machine;
  machine.head=0;
  machine.state="BEGIN";
  int args_index=1;
  while(args_index<args.length && !args[args_index].empty && args[args_index][0]=='-'){
    auto flag=args[args_index++];
    void expect_argument(){
    
    if(args_index >= args.length){
      usage(stderr);
      stderr.writeln("ERROR: No argument provided for flag `",flag,"`");
      exit(1);
    }
  }
  switch(flag){
    case "--help":
    case "-h":
      usage(stdout);
      exit(0);
      break;
    case "--state":
    case "-s":
      expect_argument();
      machine.state=args[args_index++];
      break;
    case "--head":
    case "-p":
      expect_argument();
      machine.head=args[args_index++];
      break;
    case "--head":
    case "-p":
      expect_argument();
      machine.head=args[args_index++].to!ulong;
      break;
    case "--non-interactively":
      non_interactively=true;
      break;
    default:
      usage(stderr);
      stderr.writeln("ERROR: unknown flag `",flag,"`");
      exit(1);
  }
  }
  if(args_index>=args.length){
    usage(stderr);
    stderr.writeln("ERROR: not turd imput file is provided");
    exit(1);
  }
  auto turd_filepath=args[args_index++];
  if(args_index>=args.length){
    usage(stderr);
    stderr.writeln("ERROR: not tape input file is provided");
    exit(1);
  }
  auto tape_filepath=args[args_index++];
  auto turds=readText(turd_filepath)
    .splitLines
    .map!(x=>x.strip)
    .enumerate(1)
    .filter!(x=>x.value.empty)
    .filter!(x=>x.value[0]!='#')
    .map!(x=>parseTurd(turd_filepath,x))
    .array;
  
  machine.tape=readText(tape_filepath)
    .split!isWhite
    .map!(x=>x.strip)
    .array;
  if(non_interactively){
    while(machine.next(turds)){}
    machine.dump_tape();
  }
  else{
    do{
      machine.debug_dump();
      readln();
    }
    while(machine.next(turds));
  }
  return 0;
}
