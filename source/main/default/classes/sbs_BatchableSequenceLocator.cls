/**
 * Batchable sequence starting with a job returning a QueryLocator from the start method.
 * 
 * NOTE: This wrapper class creates a new instance of the job class in the start, execute and finish methods.
 * You will also only see this wrapper class name in the Apex jobs log instead of the real job class name.
 */
global inherited sharing class sbs_BatchableSequenceLocator extends sbs_BatchableSequence implements Database.Batchable<SObject> {
    /**
     * Create new batchable sequence starting with a job returning a QueryLocator from the start method.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   New batchable sequence.
     */
    global sbs_BatchableSequenceLocator(List<JobConfig> jobConfigurations) {
        super(jobConfigurations);
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        Database.Batchable<SObject> batchableInstance = createBatchableInstance();
        return (Database.QueryLocator) batchableInstance.start(context);
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        Database.Batchable<SObject> batchableInstance = createBatchableInstance();
        batchableInstance.execute(context, scope);
    }

    global void finish(Database.BatchableContext context) {
        Database.Batchable<SObject> batchableInstance = createBatchableInstance();
        batchableInstance.finish(context);
        executeNextSuccessor();
    }
}
