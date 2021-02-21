# Salesforce Batchable Sequence

> Execute multiple batchable jobs one after another.

This SFDX project provides a small orchestration framework which allows you to execute multiple `Database.Batchable` jobs as a chained sequence.

A typical use case for this solution is processing large sets of data for different Salesforce objects where the jobs have to run one after another due to interdependencies between the records.

## Installation

Deploy this SFDX project using the source files in this Git repository.

1. Clone the repository
2. Deploy using Salesforce CLI: `sfdx force:source:deploy -p source`

## Usage

Sequences of batchable jobs should be executed using the method `sbs_BatchableSequence.execute()` with a prepared list of job configurations.

A job configuration comprises the following information:

- `className`: String value defining the Apex class to execute. This class must implement the `Database.Batchable` interface. If the start type is `DIRECT` the class must also be a subclass of `sbs_BatchableSequence`.
- `startType`: Enum value defining the start type of the job. The default is `DIRECT` which means that the given class is executed directly as batchable job and is responsible for triggering the execution of successors when it finishes. Other start types support using a batchable implementations which cannot extend the base class from this framework.
- `batchSize`: Integer value defining the number of records to process per batch. The default is 200.

### Using Subclasses of sbs_BatchableSequence

The recommended way of usage is to write implementations of the `Database.Batchable` interface which extend the base class `sbs_BatchableSequence` from this framework. Each of those batchable implementations must then call the method `super.executeNextSuccessor()` inside its `finish()` method.

Example:

```java
public inherited sharing class test_AccountBatchJob extends sbs_BatchableSequence implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account');
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Do something with accounts
    }
    public void finish(Database.BatchableContext context) {
        super.executeNextSuccessor();
    }
}
public inherited sharing class test_ContactBatchJob extends sbs_BatchableSequence implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Name FROM Contact');
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Do something with contacts
    }
    public void finish(Database.BatchableContext context) {
        super.executeNextSuccessor();
    }
}
```

Then execute the jobs using the class names in job configurations:

```java
sbs_BatchableSequence.execute(new List<sbs_BatchableSequence.JobConfig>{
    new sbs_BatchableSequence.JobConfig('test_AccountBatchJob', 10),
    new sbs_BatchableSequence.JobConfig('test_ContactBatchJob', 20)
});
```

This will first execute the Account batch job with a batch size of 10 records. When it finishes it will execute the Contact batch job with a batch size of 20 records.

### Using Delegation to Independent Batchable Classes

In case you cannot extend your `Database.Batchable` implementation from the base class `sbs_BatchableSequence` the framework can use wrapper classes and delegate execution to your implementation. However, this has some caveats.

- A new instance of your `Database.Batchable` implementation is created inside the start and finish phase of the job and for the execution of every batch. This implies that you cannot make use of `Database.Stateful` to retain state across the whole job.
- The Apex jobs view in Salesforce Setup will only display the name of the Apex wrapper classes, not the name of the classes doing the real work. Therefore, it may be hard to figure out which specific jobs have been executed.

Batchable classes still have to implement the `Database.Batchable` interface but do not need to care about triggering the execution of the next job in their `finish()` methods.

Example:

```java
public inherited sharing class test_AccountBatchJob implements Database.Batchable<SObject> {
    public Iterable<SObject> start(Database.BatchableContext context) {
        return [SELECT Id, Name FROM Account];
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Do something with accounts
    }
    public void finish(Database.BatchableContext context) {
    }
}
public inherited sharing class test_ContactBatchJob implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Name FROM Contact');
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Do something with contacts
    }
    public void finish(Database.BatchableContext context) {
    }
}
```

Then execute the jobs using the class names and the correct start types corresponding to the return type of the `start()` method:

```java
sbs_BatchableSequence.execute(new List<sbs_BatchableSequence.JobConfig>{
    new sbs_BatchableSequence.JobConfig('test_AccountBatchJob', sbs_BatchableSequence.StartType.DELEGATE_ITERABLE, 10),
    new sbs_BatchableSequence.JobConfig('test_ContactBatchJob', sbs_BatchableSequence.StartType.DELEGATE_QUERYLOCATOR, 20)
});
```

This will first execute the Account batch job using the wrapper for `Iterable` start methods. When it finishes it will execute the Contact batch job using the wrapper for `QueryLocator` start methods.

## License

[MIT](https://opensource.org/licenses/MIT)
