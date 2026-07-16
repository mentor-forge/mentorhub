# Using LLM Code Assistants

## Pitfalls

If you have ever used modern coding assistants, you have probably noticed how they can get carried away and do many things that you didn’t really intend for them to do. This is the classic AI alignment problem and will probably continue to be a barrier to effective use of these assistance without the proper technique. Having clear intent is the most important part of prompt engineering. There are three techniques that I have discovered to help manage LLM assistants: Ask, Plan, and Orchestrate:

## Ask Mode

Using Ask mode is the fastest way to control what the AI is going to do. It’s only going to answer your questions. It’s not going to modify any files. That's a great way to control the LLM, but what if you actually want to use them to do some work?

## Planning

The best way to keep a leash on the LLM is to start by asking for a clearly defined plan which describes all of the changes to be made. By asking the AI to create a plan, you give yourself an opportunity to make sure you are aligned before making changes. I use a _PLANNING.md document to describe a planning process to the LLM with important planning context, and instructions about how to document the plan. Prompts that I use for planning are then simply

```
Please create @_PLANNING tasks to close the following issue <issue text>. Only create tasks, do not execute any tasks. Only create files in the tasks folder.
```

The prompt doesn't have to be a book with tons of implementation details, just a well written issue with a clearly described goal. We what to let the LLM help plan the steps, and document all of them for our review before we execute anything. 

NOTE: If the plans seem way out of line, you can discard all of the tasks, and start over with the planning prompt, but this time with a description of what you didn't like in the first set of tasks. Don't keep bad prompts and tasks in the context window, if you are starting over, start with a new chat. Leaving bad tasks in context can cause hallucinations.

## Orchestration

Now that you have a set of tasks that the LLM created and you have reviewed, it's time to set the LLM free. I use an _ORCHESTRATE.md file to describe a task orchestration framework where tasks are executed by their own sub-agent and changes are scheduled, validated, and committed to source control by an orchestration agent. This approach can lead to very productive sessions where the LLM works unsupervised for an extended period of time, and delivers value without going off the rails. The prompt I use to start orchestration is just:

```
Please @_ORCHESTRATE all pending tasks
```

then sit back and watch the magic. After the LLM completes that work, you have some code changes to review. If your task orchestration framework did it's job, that review should be easy, with meaningful commit messages and a well described PR. 

## Starting Fresh

Starting the planning approach with a fresh chat every time, using that chat till the feature you are planning for is implemented, and then ending that chat session when the feature ships are also best practices.