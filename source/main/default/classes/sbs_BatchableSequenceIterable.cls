/**
 * Batchable sequence starting with a job returning an Iterable from the start method.
 * 
 * NOTE: This wrapper class creates a new instance of the job class in the start, execute and finish methods.
 * You will also only see this wrapper class name in the Apex jobs log instead of the real job class name.
 */
global inherited sharing class sbs_BatchableSequenceIterable extends sbs_BatchableSequence implements Database.Batchable<SObject> {
    /**
     * Create new batchable sequence starting with a job returning an Iterable from the start method.
     * 
     * @param  jobConfigurations List of job configurations.
     * @return                   New batchable sequence.
     */
    global sbs_BatchableSequenceIterable(List<JobConfig> jobConfigurations) {
        super(jobConfigurations);
    }

    global Iterable<SObject> start(Database.BatchableContext context) {
        Database.Batchable<SObject> currentJobInstance = super.createCurrentJobInstance();
        return currentJobInstance.start(context);
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        Database.Batchable<SObject> currentJobInstance = super.createCurrentJobInstance();
        currentJobInstance.execute(context, scope);
    }

    global void finish(Database.BatchableContext context) {
        Database.Batchable<SObject> currentJobInstance = super.createCurrentJobInstance();
        currentJobInstance.finish(context);
        super.executeNextSuccessor();
    }
}
