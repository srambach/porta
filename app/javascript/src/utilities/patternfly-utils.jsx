// @flow

import React from 'react'

import {
  SelectOption,
  SelectOptionObject as ISelectOptionObject
} from '@patternfly/react-core'

interface Record {
  id: string | number,
  name: string,
  systemName: string
}

type Props = Record & {
  disabled?: boolean,
  className?: string,
  description?: string
}

export class SelectOptionObject implements ISelectOptionObject {
  id: string;
  name: string;
  systemName: string; // TODO: use SelectOption's description instead when PF package is up-to-date

  constructor (item: Record) {
    this.id = String(item.id)
    this.name = item.name
    this.systemName = item.systemName
  }

  toString (): string {
    return this.systemName ? `${this.name} (${this.systemName})` : this.name
  }

  compareTo (other: Record): boolean {
    return this.id === other.id
  }
}

export const toSelectOption = ({ id, name, systemName, disabled = false, className, description }: Props) => (
  <SelectOption
    key={id}
    value={new SelectOptionObject({ id, name, systemName })}
    isDisabled={disabled}
    className={className}
    description={description}
  />
)
