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
    <div class="trace-detail-chart-logs">
        <div class="rk-trace-t-loading" v-show="loading">
            <svg class="icon loading">
                <use xlink:href="#spinner"></use>
            </svg>
        </div>
        <TraceLogsDetail :data="logsData"></TraceLogsDetail>
    </div>
</template>
<style lang="scss">
    .rk-tooltip-popper.trace-table-tooltip .rk-tooltip-inner {
        max-width: 600px;
    }

    .trace-detail-chart-table {
        position: relative;
        min-height: 150px;
    }
</style>

<script lang="js">
    import copy from '@/utils/copy';
    import Item from './trace-chart-table/trace-item';
    import TraceContainer from './trace-chart-table/trace-container';
    import TraceLogsDetail from './trace-chart-logs/trace-logs-detail';

    /* eslint-disable */
    /* tslint:disable */
    export default {
        components: {
            Item,
            TraceContainer,
            TraceLogsDetail
        },
        props: ['data', 'traceId'],
        watch: {
            data(val, oldVal) {
                if (!this.data.length) {
                    return;
                }
                this.logsData = this.formatData(this.data);
                this.loading = false;
            },
        },
        data() {
            return {
                logsData: [],
                diaplay: true,
                // segmentId: [],
                showDetail: false,
                list: [],
                currentSpan: [],
                loading: true,
            };
        },
        methods: {
            copy,
            formatData(arr) {
                if (!arr || arr.length === 0) {
                    return [];
                }
                const allLogs = [];
                //数据：{name: '{服务名}', nodes: [{日志节点数据}]}
                const serviceLogs = [{
                    'name': 'ALL',
                    nodes: allLogs
                }];
                const serviceMap = {'ALL': allLogs};
                for (const item of arr) {
                    if (item.endpointName && (item.endpointName.startsWith('log/') || item.logs && item.logs.length > 0)) {
                        let serviceCode = item.serviceCode;
                        let serviceNodeLogs = serviceMap[serviceCode];
                        if (!serviceNodeLogs) {
                            serviceNodeLogs = {
                                name: serviceCode,
                                nodes: []
                            };
                            serviceLogs.push(serviceNodeLogs);
                            serviceMap[serviceCode] = serviceNodeLogs;
                        }
                        serviceNodeLogs.nodes.push(item);
                        allLogs.push(item);
                    }
                }

                return serviceLogs;
            },
            traverseTree(node, spanId, segmentId, data) {
                if (!node) {
                    return;
                }
                if (node.spanId === spanId && node.segmentId === segmentId) {
                    node.children.push(data);
                    return;
                }
                if (node.children && node.children.length > 0) {
                    for (const item of node.children) {
                        this.traverseTree(item, spanId, segmentId, data);
                    }
                }
            },
            collapse(d) {
                if (d.children) {
                    let dur = d.endTime - d.startTime;
                    d.children.forEach((i) => {
                        dur -= (i.endTime - i.startTime);
                    });
                    d.dur = dur < 0 ? 0 : dur;
                    d.children.forEach((i) => this.collapse(i));
                }
            },
            handleSelectSpan(data) {
                this.currentSpan = data;
                this.showDetail = true;
            },
            showCurrentSpanDetail(title, text) {
                const textLineNumber = text.split('\n').length;
                let textHeight = textLineNumber * 20.2 + 10;
                const tmpHeight = window.innerHeight * 0.9;
                textHeight = textHeight >= tmpHeight ? tmpHeight : textHeight;
                this.$modal.show('dialog', {
                    title,
                    text: `<div style="height:${textHeight}px">${text}</div>`,
                    buttons: [
                        {
                            title: 'Copy',
                            handler: () => {
                                this.copy(text);
                            },
                        },
                        {
                            title: 'Close',
                        },
                    ],
                })
            },
        },
        created() {
            this.loading = true;
        },
        mounted() {
            this.logsData = this.formatData(this.data);
            this.loading = false;
            this.$eventBus.$on('HANDLE-SELECT-SPAN', this, this.handleSelectSpan);
            this.$eventBus.$on('TRACE-TABLE-LOADING', this, () => {
                this.loading = true
            });
        },
    };
</script>
<style>
    .dialog-c-text {
        white-space: pre;
        overflow: auto;
        font-family: monospace;
    }
</style>
