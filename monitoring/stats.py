import logging
import requests
from datetime import datetime, timezone
from database import Build, Stage


def get_job_from_resp(job_name, build_url, resp):
    timestamp = int(resp['endTimeMillis'] / 1000)
    build = Build(job_name=job_name,
                  build_id=resp['id'],
                  build_url=build_url,
                  finished_at_secs=timestamp,
                  status=resp['status'],
                  duration_millis=resp['durationMillis'])

    if 'stages' in resp.keys():
        for resp_stage in resp['stages']:
            stage = Stage(name=resp_stage['name'],
                          status=resp_stage['status'],
                          duration_millis=resp_stage['durationMillis'])
            build.stages.append(stage)

    return build


def get_build_stats_endpoint(build_url):
    return '{}/wfapi/describe'.format(build_url)


def get_build_stats(job_name, build_url):
    build_stats_url = get_build_stats_endpoint(build_url)
    resp = requests.get(build_stats_url)
    if resp.status_code == 200:
        return get_job_from_resp(job_name=job_name, build_url=build_url, resp=resp.json())
    else:
        return None


def collect_and_push_build_stats(job_name, build_url, db_session):
    job = get_build_stats(job_name, build_url)
    db_session.add(job)
    db_session.commit()
