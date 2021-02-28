# Salesforce Batchable Sequence

> Execute multiple Salesforce batchable or queueable Apex jobs one after another.

![GitHub version](https://img.shields.io/github/package-json/v/georgwittberger/salesforce-batchable-sequence)
![GitHub issues](https://img.shields.io/github/issues/georgwittberger/salesforce-batchable-sequence)
![GitHub license](https://img.shields.io/github/license/georgwittberger/salesforce-batchable-sequence)

This SFDX project provides a small orchestration framework which allows you to execute multiple `Database.Batchable` or `Queueable` jobs as a chained sequence.

A typical use case for this solution is processing large sets of data for different Salesforce objects where the jobs have to run one after another due to interdependencies between the records.

- [Salesforce Batchable Sequence](#salesforce-batchable-sequence)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Job Configuration](#job-configuration)
    - [Job Start Types](#job-start-types)
    - [Using Subclasses of sbs_JobSequence](#using-subclasses-of-sbs_jobsequence)
    - [Using Delegation to Independent Batchable Classes](#using-delegation-to-independent-batchable-classes)
  - [Limitations](#limitations)
  - [License](#license)

## Installation

<a href="https://githubsfdeploy.herokuapp.com?owner=georgwittberger&repo=salesforce-batchable-sequence&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Or deploy this SFDX project using the source files in this Git repository.

1. Clone the repository
2. Deploy using Salesforce CLI: `sfdx force:source:deploy -p source`

## Usage

Sequences of jobs should be executed using the static method `sbs_JobSequence.execute()` which takes a `List<sbs_JobSequence.JobConfig>` as argument.

### Job Configuration

The class `sbs_JobSequence.JobConfig` defines the configuration of a job. It provides several constructors for flexible instantiation.

The configuration contains the following fields:

- `className`: String value defining the Apex class to execute. This class must be instantiable via default constructor (without any parameters) and depending on the start type it must fulfill further requirements (see below).
- `startType`: Enum value defining the start type of the job. The default is `BATCH_DIRECT`.
- `batchSize`: Integer value defining the number of records to process per batch. The default is 200.
- `data`: String value with additional data which should be available inside the job. Tipp: Use `JSON.serialize()` to pack more complex data structures into this field and then deserialize them inside the job.

### Job Start Types

- **QUEUEABLE_DIRECT:** Execute Apex class directly as `Queueable`. The class must extend `sbs_JobSequence` and implement `Queueable`.
- **BATCH_DIRECT:** Execute Apex class directly as `Database.Batchable`. The class must extend `sbs_JobSequence` and implement `Database.Batchable`.
- **BATCH_ITERABLE:** Execute Apex class using `sbs_BatchableSequenceIterable` wrapper. The class must implement `Database.Batchable` and return an `Iterable` from the start method.
- **BATCH_QUERYLOCATOR:** Execute Apex class using `sbs_BatchableSequenceLocator` wrapper. The class must implement `Database.Batchable` and return a QueryLocator from the start method.

### Using Subclasses of sbs_JobSequence

The recommended way of writing jobs is to extend the Apex class `sbs_JobSequence` provided by this framework and implement either the `Database.Batchable` or `Queueable` interface. At the end of its execution the job must call the inherited method `executeNextSuccessor()`. Batchable jobs will do this inside the finish method while queueable jobs will just invoke it at the end of their execute method.

Example:

```java
public inherited sharing class AccountBatchJob extends sbs_JobSequence implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id FROM Account WHERE Name LIKE \'Demo%\'');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Account> accounts = (List<Account>) scope;
        for (Account account : accounts) {
            account.Type = 'Prospect';
        }
        update accounts;
    }

    public void finish(Database.BatchableContext context) {
        executeNextSuccessor();
    }
}

public inherited sharing class ContactBatchJob extends sbs_JobSequence implements Database.Batchable<Contact> {
    public Iterable<Contact> start(Database.BatchableContext context) {
        Map<String, Object> jobData = (Map<String, Object>) JSON.deserializeUntyped(getCurrentJobConfiguration().data);
        String accountType = (String) jobData.get('accountType');
        return [SELECT Id FROM Contact WHERE Account.Type = :accountType];
    }

    public void execute(Database.BatchableContext context, List<Contact> scope) {
        Map<String, Object> jobData = (Map<String, Object>) JSON.deserializeUntyped(getCurrentJobConfiguration().data);
        for (Contact contact : scope) {
            contact.LeadSource = (String) jobData.get('leadSource');
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
        executeNextSuccessor();
    }
}

public inherited sharing class ContactQueueableJob extends sbs_JobSequence implements Queueable {
    public void execute(QueueableContext context) {
        String leadSource = getCurrentJobConfiguration().data;
        List<Contact> contacts = [SELECT Id FROM Contact WHERE LeadSource = :leadSource];
        for (Contact contact : contacts) {
            contact.Description = 'Comes from ' + leadSource;
        }
        update contacts;
        executeNextSuccessor();
    }
}
```

Then execute the jobs using the following job configurations:

```java
sbs_JobSequence.execute(new List<sbs_JobSequence.JobConfig>{
    new sbs_JobSequence.JobConfig('AccountBatchJob', 100),
    new sbs_JobSequence.JobConfig(
        'ContactBatchJob', 250,
        JSON.serialize(new Map<String, Object>{
            'accountType' => 'Prospect',
            'leadSource' => 'Web'
        })
    ),
    new sbs_JobSequence.JobConfig(
        'ContactQueueableJob',
        sbs_JobSequence.StartType.QUEUEABLE_DIRECT,
        'Web'
    )
});
```

This will first execute the Account batch job with a batch size of 100 records. When it finishes it will execute the Contact batch job with a batch size of 250 records and the given job data which can be accessed anytime inside the job via the `data` property of the job configuration. When the second job has finished the sequence will execute the final queueable job.

### Using Delegation to Independent Batchable Classes

In case you cannot extend your `Database.Batchable` implementation from the base class `sbs_JobSequence` the framework can use wrapper classes and delegate execution to your implementation. However, this has some caveats.

- A new instance of your `Database.Batchable` implementation is created inside the start and finish methods of the job and for the execution of every batch. This implies that you cannot make use of `Database.Stateful` to retain state across the whole job. The instance of your class is not managed by the Salesforce scheduling framework anymore.
- The Apex jobs view in Salesforce Setup will only display the name of the Apex wrapper classes, not the name of the classes doing the real work. Therefore, it may be hard to figure out which specific jobs have been executed.

Batchable classes still have to implement the `Database.Batchable` interface but do not need to care about triggering the execution of the next job in their finish methods.

Example:

```java
public inherited sharing class AccountBatchJob implements Database.Batchable<SObject> {
    public Iterable<SObject> start(Database.BatchableContext context) {
        return [SELECT Id, Name FROM Account];
    }
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Do something with accounts
    }
    public void finish(Database.BatchableContext context) {
    }
}
public inherited sharing class ContactBatchJob implements Database.Batchable<SObject> {
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

Then execute the jobs using the class names and the correct start types corresponding to the return types of the start methods:

```java
sbs_JobSequence.execute(new List<sbs_JobSequence.JobConfig>{
    new sbs_JobSequence.JobConfig('AccountBatchJob', sbs_JobSequence.StartType.BATCH_ITERABLE, 10),
    new sbs_JobSequence.JobConfig('ContactBatchJob', sbs_JobSequence.StartType.BATCH_QUERYLOCATOR, 20)
});
```

This will first execute the Account batch job using the wrapper for `Iterable` start methods. When it finishes it will execute the Contact batch job using the wrapper for `QueryLocator` start methods.

## Limitations

Instances of job classes must be instantiated via default constructor. Therefore, you cannot use the constructor to pass any parameters to the jobs. Use the field `data` in the job configuration instead.

## License

[MIT](https://opensource.org/licenses/MIT)
