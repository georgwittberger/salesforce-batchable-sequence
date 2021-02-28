@IsTest
class sbs_BatchableSequenceLocatorTest {
    @IsTest
    static void executesBatchableMethods() {
        Test.startTest();
        sbs_BatchableSequenceIterable batchableSequence = new sbs_BatchableSequenceIterable(new List<sbs_JobSequence.JobConfig>{
            new sbs_JobSequence.JobConfig('sbs_BatchableLocatorMock', sbs_JobSequence.StartType.BATCH_QUERYLOCATOR, 240, 'First Data'),
            new sbs_JobSequence.JobConfig('sbs_BatchableLocatorMock', sbs_JobSequence.StartType.BATCH_QUERYLOCATOR, 120, 'Second Data')
        });
        batchableSequence.start(null);
        System.assertEquals(1, sbs_BatchableLocatorMock.startInvocations, 'First batchable job should have been started');
        batchableSequence.execute(null, null);
        System.assertEquals(1, sbs_BatchableLocatorMock.executeInvocations, 'First batchable job should have been executed');
        batchableSequence.finish(null);
        System.assertEquals(1, sbs_BatchableLocatorMock.finishInvocations, 'First batchable job should have been finished');
        System.assertEquals(1, sbs_BatchableLocatorMock.startInvocations, 'Second batchable job should not have been started yet');
        Test.stopTest();
        System.assertEquals(2, sbs_BatchableLocatorMock.startInvocations, 'Second batchable job should have been started');
        System.assertEquals(2, sbs_BatchableLocatorMock.executeInvocations, 'Second batchable job should have been executed');
        System.assertEquals(2, sbs_BatchableLocatorMock.finishInvocations, 'Second batchable job should have been finished');
    }
}
