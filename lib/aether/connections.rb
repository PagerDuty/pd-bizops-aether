require 'restforce'
require 'executrix'
require 'pg'
require 'aws-sdk-v1'

module Aether
  class Connections
    attr_reader(
      :salesforce,
      :salesforce_bulk,
      :redshift,
      :s3,
      :aws_access_key,
      :aws_secret_key)

    def initialize(
      salesforce_user:,
      salesforce_password:,
      salesforce_client_id:,
      salesforce_client_secret:,
      salesforce_is_sandbox:,
      redshift_user:,
      redshift_password:,
      redshift_host:,
      redshift_port:,
      redshift_dbname:,
      aws_access_key:,
      aws_secret_key:)

      if salesforce_is_sandbox
        salesforce_host = 'test.salesforce.com'
      else
        salesforce_host = 'login.salesforce.com'
      end

      # set api version to 33.0 (spring 15)
      # to fix: Idea.IsLocked field not getting recognized on API 26.0 apex class
      # https://success.salesforce.com/issues_view?id=a1p30000000T3tyAAC
      salesforce_api_version = '33.0'

      @salesforce = ::Restforce.new(
        username: salesforce_user,
        password: salesforce_password,
        client_id: salesforce_client_id,
        client_secret: salesforce_client_secret,
        host: salesforce_host,
        api_version: salesforce_api_version)

      @salesforce_bulk = ::Executrix::Api.new(
        salesforce_user,
        salesforce_password,
        salesforce_is_sandbox,
        salesforce_api_version)

      # save redshift credentials because we need to be able to
      # reconnect if we fork
      @redshift_user = redshift_user
      @redshift_password = redshift_password
      @redshift_host = redshift_host
      @redshift_port = redshift_port
      @redshift_dbname = redshift_dbname
      reestablish_redshift

      @s3 = ::AWS::S3.new(
        access_key_id: aws_access_key,
        secret_access_key: aws_secret_key)

      # need to expose these because redshift requires these in the
      # copy command when bulk loading
      @aws_access_key = aws_access_key
      @aws_secret_key = aws_secret_key
    end

    def reestablish_redshift
      @redshift = ::PG.connect(
        user: @redshift_user,
        password: @redshift_password,
        host: @redshift_host,
        port: @redshift_port,
        dbname: @redshift_dbname)
    end
  end
end
