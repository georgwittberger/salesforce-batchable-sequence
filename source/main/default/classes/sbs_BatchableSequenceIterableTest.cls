@IsTest
class sbs_BatchableSequenceIterableTest {
    @IsTest
    static void executesBatchableMethods() {
        Test.startTest();
        sbs_BatchableSequenceIterable batchableSequence = new sbs_BatchableSequenceIterable(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('sbs_BatchableIterableMock', sbs_JobSequence.StartType.BATCH_ITERABLE, 240, 'First Data'),
            new sbs_JobSequence.JobConfig('sbs_BatchableIterableMock', sbs_JobSequence.StartType.BATCH_ITERABLE, 120, 'Second Data')
        });
        batchableSequence.start(null);
        System.assertEquals(1, sbs_BatchableIterableMock.startInvocations, 'First batchable job should have been started');
        batchableSequence.execute(null, null);
        System.assertEquals(1, sbs_BatchableIterableMock.executeInvocations, 'First batchable job should have been executed');
        batchableSequence.finish(null);
        System.assertEquals(1, sbs_BatchableIterableMock.finishInvocations, 'First batchable job should have been finished');
        System.assertEquals(1, sbs_BatchableIterableMock.startInvocations, 'Second batchable job should not have been started yet');
        Test.stopTest();
        System.assertEquals(2, sbs_BatchableIterableMock.startInvocations, 'Second batchable job should have been started');
        System.assertEquals(2, sbs_BatchableIterableMock.executeInvocations, 'Second batchable job should have been executed');
        System.assertEquals(2, sbs_BatchableIterableMock.finishInvocations, 'Second batchable job should have been finished');
    }
}
