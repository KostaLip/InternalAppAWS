data "aws_ssoadmin_instances" "sso" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}

locals {
  group_names = [
    "Admins@lab.local", "StorageAdmins@lab.local", "StorageReaders@lab.local", "ComputeAdmins@lab.local", "ComputeReaders@lab.local", "LogReaders@lab.local"
  ]
}

data "aws_identitystore_group" "groups" {
  for_each = toset(local.group_names)

  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path = "DisplayName"
      attribute_value = each.value
    }
  }
}

locals {
  permission_sets = {
    Admins = {
        description = "Full Admin access"
        policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
        session_dur = "PT8H"
    }
    StorageAdmins = {
        description = "Full storage admin acces for S3"
        policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        session_dur = "PT8H"
    }
    StorageReaders = {
      description = "Read-only access for S3"
      policy_arn  = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      session_dur = "PT4H"
    }
    ComputeAdmins = {
      description = "Full Admin Acces for Lambda"
      policy_arn  = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
      session_dur = "PT8H"
    }
    ComputeReaders = {
      description = "Read-only access for Lambda"
      policy_arn  = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
      session_dur = "PT4H"
    }
    LogReaders = {
        description = "Read-only access for CloudTrail logs"
        policy_arn  = "arn:aws:iam::aws:policy/AWSCloudTrail_ReadOnlyAccess"
        session_dur = "PT4H"
    }
  }
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = local.sso_instance_arn
  session_duration = each.value.session_dur
}

locals {
  additional_policies = {
    compute_admins_apigw = {
      permission_set = "ComputeAdmins"
      policy_arn      = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
    }
    compute_readers_apigw = {
      permission_set = "ComputeReaders"
      policy_arn      = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
    }
    storage_admins_datasync = {
      permission_set = "StorageAdmins"
      policy_arn = "arn:aws:iam::aws:policy/AWSDataSyncFullAccess"
    }
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "additional" {
  for_each = local.additional_policies

  instance_arn        = local.sso_instance_arn
  permission_set_arn  = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  managed_policy_arn  = each.value.policy_arn
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.permission_sets

  instance_arn        = local.sso_instance_arn
  permission_set_arn  = aws_ssoadmin_permission_set.this[each.key].arn
  managed_policy_arn  = each.value.policy_arn
}

locals {
  assignments = {
    admins_management = {
      group          = "Admins@lab.local"
      permission_set = "Admins"
      account_id     = "093410165669"
    }
    admins_storage_s3 = {
      group = "Admins@lab.local"
      permission_set = "Admins"
      account_id = "649437299651"
    }
    admins_storage_datasync = {
      group = "Admins@lab.local"
      permission_set = "Admins"
      account_id = "187069338250"
    }
    admins_compute = {
      group = "Admins@lab.local"
      permission_set = "Admins"
      account_id = "803888670729"
    }
    admins_logs = {
      group = "Admins@lab.local"
      permission_set = "Admins"
      account_id = "734648185871"
    }
    compute_admins = {
      group = "ComputeAdmins@lab.local"
      permission_set = "ComputeAdmins"
      account_id = "803888670729"
    }
    compute_readers = {
      group = "ComputeReaders@lab.local"
      permission_set = "ComputeReaders"
      account_id = "803888670729"
    }
    storage_admins_s3 = {
      group = "StorageAdmins@lab.local"
      permission_set = "StorageAdmins"
      account_id = "649437299651"
    }
    storage_admins_datasync = {
      group = "StorageAdmins@lab.local"
      permission_set = "StorageAdmins"
      account_id = "187069338250"
    }
    storage_readers_datasync = {
      group = "StorageReaders@lab.local"
      permission_set = "StorageReaders"
      account_id = "187069338250"
    }
    storage_readers_s3 = {
      group = "StorageReaders@lab.local"
      permission_set = "StorageReaders"
      account_id = "649437299651"
    }
    log_readers = {
      group = "LogReaders@lab.local"
      permission_set = "LogReaders"
      account_id = "734648185871"
    }
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = data.aws_identitystore_group.groups[each.value.group].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}