/**
* Licensed to the Apache Software Foundation (ASF) under one or more
* contributor license agreements.  See the NOTICE file distributed with
* this work for additional information regarding copyright ownership.
* The ASF licenses this file to You under the Apache License, Version 2.0
* (the "License"); you may not use this file except in compliance with
* the License.  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
<template>
    <div class="trace-logs-tabs">
        <ul class="trace-logs-tabs-title scroll_hide">
            <li v-for="serviceNode in logsData" :class="{'active': serviceNode.name === currentServiceName}"
                @click="showLogs(serviceNode.name, serviceNode.nodes)">
                {{serviceNode.name}} ({{serviceNode.nodes.length}})
            </li>
        </ul>
        <div class="trace-logs-list">
            <template v-for="serviceNode of currentLogs">
                <div class="log-item" v-for="item of serviceNode.logs" :class="{'error': item.event === 'error'}">
                    <pre>{{timeFormat(item.time)}} [{{item.event}}] {{item.logName}}<template v-if="!item.stack">{{item.message}}</template>{{item.stack}}</pre>
                </div>
            </template>
        </div>
    </div>
</template>
<style lang="scss" scoped>
    .trace-logs-tabs {
        width: 100%;
    }

    .trace-logs-tabs-title {
        width: 20%;
        overflow: hidden;
        float: left;
        height: 100%;
        border-right: 1px solid #eeeeee;
    }

    .trace-logs-tabs-title > li {
        padding: 8px 10px;
        cursor: pointer;
        border-bottom: 1px solid rgba(0, 0, 0, 0.07);
    }

    .trace-logs-tabs-title > li:hover {
        background: rgba(0, 0, 0, 0.04);
    }

    .trace-logs-tabs-title > li.active {
        background: #ededed;
    }

    .trace-logs-tabs-title > li.error {
        color: red;
    }

    .trace-logs-list {
        float: right;
        width: 79%;
        flex: 1;
        height: 100%;
        overflow: scroll;
    }

    .log-item {
        padding: 2px 10px;
        border-radius: 3px;
        margin-top: 10px;
        background-color: #e6f7ff;
        border: 1px solid #91d5ff;
        display: inline-block;
        clear: both;
        float: left;
    }

    .log-item.error {
        background-color: #fff1f0;
        border: 1px solid #ffa39e;
    }

    .log-item.error > .log-item-message {
        color: red;
    }

    .log-item > pre {
        margin-top: 0;
        margin-bottom: 0;
    }

</style>
<script lang="js">
    import timestampToTime from '@/utils/timestampToTime';

    export default {
        name: 'item',
        props: ['data'],
        watch: {
            data(val, oldVal) {
                this.dataFormat(this.data);
            },
        },
        data() {
            return {
                logsData: [],
                currentLogs: [],
                currentServiceName: '',
            };
        },
        methods: {
            toggle() {
                this.displayChildren = !this.displayChildren;
            },
            showSelectSpan() {
                this.$eventBus.$emit('HANDLE-SELECT-SPAN', this.data);
            },
            showLogs(serviceName, logs) {
                this.currentServiceName = serviceName;
                this.currentLogs = logs;
            },
            timeFormat(timestamp) {
                return timestampToTime(timestamp);
            },

            dataFormat(serviceNodes) {
                if (!serviceNodes || !serviceNodes.length) {
                    this.currentServiceName = '';
                    this.currentLogs = [];
                    this.logsData = [];
                    return;
                }

                serviceNodes.forEach((serviceNode) => {
                    serviceNode.nodes.forEach((span) => {
                        const logs = [];
                        span.logs.forEach((logList) => {
                            const logInfo = {};
                            logList.data.forEach((o) => {
                                let value = o.value;
                                if (o.key === 'stack') {
                                    value = value.replace(/\nat\s/g, '\n  at ');
                                }
                                logInfo[o.key] = value;
                            });
                            logInfo.time = span.startTime;
                            logs.push(logInfo);
                        });
                        span.logs = logs;

                    });
                });

                this.logsData = serviceNodes;
                if (this.logsData && this.logsData.length) {
                    const serviceNode = this.logsData[0];
                    this.currentServiceName = serviceNode.name;
                    this.currentLogs = serviceNode.nodes;
                } else {
                    this.currentServiceName = '';
                    this.currentLogs = [];
                }
            },
        },
        mounted() {
            this.dataFormat(this.data);
        },
    };
</script>
