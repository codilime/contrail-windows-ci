from sqlalchemy import BigInteger, ForeignKey, Column, DateTime, Integer, String
from sqlalchemy.ext.declarative import declarative_base


MonitoringBase = declarative_base()


class Job(MonitoringBase):
    __tablename__ = 'jobs'

    id = Column(Integer, primary_key=True)
    build_url = Column(String(4096))
    build_id = Column(Integer)
    finished_at = Column(DateTime)
    status = Column(String(4096))
    duration = Column(BigInteger)

    def __repr__(self):
        return "<Job(id={}, build_id={})>".format(self.id, self.build_id)


class Stage(MonitoringBase):
    __tablename__ = 'stages'

    id = Column(Integer, primary_key=True)
    job_id = Column(Integer, ForeignKey('jobs.id'))
    name = Column(String(4096))
    status = Column(String(4096))
    duration = Column(BigInteger)

    def __repr__(self):
        return "<Stage(id={})>".format(self.id)
