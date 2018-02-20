import requests


class JobNotFoundException(Exception):
    pass


class JobStats(object):
    def __init__(self, resp):
        self.id = resp['id']
        self.status = resp['status']
        self.duration = resp['durationMillis']


class Jenkins(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def get_job_stats(self, job_path, build_id):
        resp = self._get_job_description(job_path=job_path, build_id=build_id)
        if resp.status_code != 200:
            raise JobNotFoundException("Job with id {} not found".format(build_id))
        return JobStats(resp.json())

    def _get_job_description(self, job_path, build_id):
        url = get_job_stats_url(self.host, self.port, job_path, build_id)
        return requests.get(url)


def get_job_stats_url(host, port, job_path, build_id):
    return 'http://{}:{}/{}/{}/wfapi/describe'.format(host, port, job_path, build_id)


def get_build_api_endpoint(build_url):
    return '{}/wfapi/describe'.format(build_url)
