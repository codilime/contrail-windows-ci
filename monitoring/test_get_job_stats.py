import mock
import unittest
import requests_mock
from stats import *


class TestGetJobStats(unittest.TestCase):
    def setUp(self):
        self.fake_host = 'localhost'
        self.fake_port = 8080
        self.jenkins = Jenkins(self.fake_host, self.fake_port)

    def test_can_get_job_stats(self):
        with requests_mock.mock() as m:
            m.get('http://localhost:8080/job/MyJob/1/wfapi/describe', json={
                'status': 'SUCCESS',
                'durationMillis': 1000,
                'id': 1
            })
            stats = self.jenkins.get_job_stats(job_path='job/MyJob', build_id=1)
            self.assertIsNotNone(stats)
            self.assertEqual(stats.status, 'SUCCESS')

    def test_throws_when_invalid_build_id(self):
        stats = None
        with requests_mock.mock() as m:
            m.get('http://localhost:8080/job/MyJob/-1/wfapi/describe', json={}, status_code=404)
            with self.assertRaises(JobNotFoundException) as ctx:
                self.jenkins.get_job_stats(job_path='job/MyJob', build_id=-1)
            self.assertIsNone(stats)


class TestEndpointConstructor(unittest.TestCase):
    def test_job_stats_url_is_good(self):
        url = get_job_stats_url(host='localhost', port=8080, job_path='job/MyJob', build_id=1)
        self.assertEqual(url, 'http://localhost:8080/job/MyJob/1/wfapi/describe')


class TestGetBuildApiEndpoint(unittest.TestCase):
    def test_build_api_endpoint_is_good(self):
        url = get_build_api_endpoint(build_url='http://localhost:8080/job/MyJob/1')
        self.assertEqual(url, 'http://localhost:8080/job/MyJob/1/wfapi/describe')


if __name__ == '__main__':
    unittest.main()
