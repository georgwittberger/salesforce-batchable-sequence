/**
 * Batchable sequence starting with a job returning a QueryLocator from the start method.
 */
global inherited sharing class sbs_BatchableSequenceLocator extends sbs_BatchableSequence implements Database.Batchable<SObject> {
    /**
     * Create new batchable sequence with current job returning a QueryLocator from the start method.
     * 
     * @param  currentJobConfig    Current job configuration.
     * @param  successorJobsConfig List of successor configurations.
     * @return                     New batchable sequence.
     */
    global sbs_BatchableSequenceLocator(JobConfig currentJobConfig, List<JobConfig> successorJobsConfig) {
        super(currentJobConfig, successorJobsConfig);
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        Database.Batchable<SObject> currentJobInstance = super.createCurrentJobInstance();
        return (Database.QueryLocator) currentJobInstance.start(context);
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
