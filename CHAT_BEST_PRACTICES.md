# Using LLM Code Assistants

## Pitfalls

If you have ever even played with modern coding assistants, you have probably noticed how they can get carried away and do many things that you didn’t really intend for them to do. Having clear intent is the most important part of prompt engineering. There are three techniques that I have discovered to help manage LLM assistants: Ask, Plan, and Orchestrate:

## Ask Mode

Using Ask mode is the fastest way to control what the AI is going to do. It’s only going to answer your questions. It’s not going to modify any files. That's a great way to control the LLM, but what if you actually want to use them to do some work?

## Planning

The best way to keep a leash on the LLM is to have a clearly defined plan-then-orchestrate process. You should have a README for task automation that the LLM will use as a guide for planning, and orchestrating work. The idea in planning is to make sure we are fully aligned with what the AI intends to implement. Planning prompts should always start with a fresh chat, and open with references to key context files. (READMEs, Standards, the Task Automation README...). The prompt itself should ask for planning files (tasks). Just ask for a set of tasks to accomplish some goals. The prompt doesn't have to be a book with tons of implementation details, we what to let the LLM help plan the steps, and document all of them for our review before we execute anything. During planning you should constrain the LLM with a folder level guardrail like "Only create files in the tasks folder". The prompt should also include an execution guardrail like "Only create tasks, do not execute any tasks" 

In general you should review and edit the tasks manually. If you find that the tasks are way off from what you wanted, reject all of the changes using git, and start again with a new chat and a revised planning prompt that includes information to avoid what you didn't like about the first set of tasks. Don't keep bad planning prompts in the chat context, they can lead to halusitations during orchestration. If the tasks are mostly ok, but you notice a pattern to mistakes, that is a good time to ask the LLM to fix the pattern, not the individual mistakes. 

## Orchestration

Now that you have a task automation framework, and you have created and reviewed the tasks that clearly define all of the files that will be changed and all of the goals in those changes, and how the changes will be tested for completness, the easy part is a prompt that simply says. 

```
Please orchestrate all pending tasks
```

then sit back and watch the magic. After the LLM completes that work, you have some code changes to review. If your task automation framework did it's job, that review should be easy, with meaningful commit messages and a well described PR. 

## Starting Fresh

Starting the planning approach with a fresh chat every time, using that chat till the feature you are planning for is implementated, and then ending that chat session when the feature ships are also best practices.