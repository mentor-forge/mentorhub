# Using a LLM Code Assistant

## Pitfalls
If you have ever even played with modern coding assistants,you have probably noticed how they can get carried away and do many things that you didn’t really intend for them to do. 
Having clear intent is the most important part of prompt engineering. 
i'm not talking about writing a prompt that is as long as a book with all of your detailed requirements.
If you want to leave room for the LLM to really contribute, there are three techniques that you should employ

## Ask Mode
Using Ask mode is the fastest way to control what the AI is going to do. 
It’s only going to answer your questions. It’s not going to modify any files.
That's a great way to control the LLM but what if you actually want to do some work?
 
## Planning for Orchestration
You need to prepare for orchestration. You should have a clearly defined planning approach, documented in a task automation README 
The LLM will use that framework as a guide for planning.
The idea in planning is to make sure we are fully aligned with what the AI intends to implement. 
Planning prompts should always start with a fresh chat. 
The prompt should open with references to key context files. README, standards, utilities, etc. 
The prompt itself should ask for planning files. 
Just ask for a plan to acomplish some goals. The prompt doesn't have to have all the details for the plan. 
We're going to let the LLM decide what the steps are and document all of them for our review before we execute anything.
During planning you should constraine the LLM to only editing files the target tasks folder.
The prompt should include and execution safeguard like "Only create tasks, do not execute any tasks" that folder.

## Orchestration 
now that you have a task automation framework , and you have created tasks that clearly defined all of the files that will be changed and all of the goals in those changes, 
the easy part is a prompt that simply says 
"Pleas orchestrate all pending tasks"

## Start Fresh
Starting the planning approach with a fresh chat every time, 
using that chat till the feature you are planning for implementation, 
and then ending that chat session when the feature ships 
are also best practices.